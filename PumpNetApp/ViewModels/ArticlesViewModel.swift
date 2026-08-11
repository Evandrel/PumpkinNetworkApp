import Foundation
@MainActor final class ArticlesViewModel:ObservableObject{
    @Published private(set)var articles:[WordPressArticle]=[]
    @Published private(set)var isLoading=false
    @Published private(set)var isLoadingMore=false
    @Published private(set)var errorMessage:String?
    @Published private(set)var hasLoadedOnce=false
    @Published private(set)var animationTrigger=0
    @Published var searchText=""
    private struct CachedFeed:Codable{let articles:[WordPressArticle];let page:Int;let hasMore:Bool}
    private let service:WordPressService
    private var page=1
    private var hasMore=true
    init(service:WordPressService=WordPressService()){
        self.service=service
        if let data=UserDefaults.standard.data(forKey:AppCache.articleFeedKey),let cache=try? JSONDecoder().decode(CachedFeed.self,from:data){articles=cache.articles;page=cache.page;hasMore=cache.hasMore;hasLoadedOnce=true}
        else if let legacy=Self.legacyCachedArticles(){articles=legacy;hasMore=legacy.count==10;hasLoadedOnce=true;saveCache()}
    }
    private static func legacyCachedArticles()->[WordPressArticle]?{var components=URLComponents(string:"https://www.pcl2.top/wp-json/wp/v2/posts")!;components.queryItems=[.init(name:"page",value:"1"),.init(name:"per_page",value:"10"),.init(name:"_fields",value:"id,date,link,title,excerpt")];guard let url=components.url else{return nil};var request=URLRequest(url:url,cachePolicy:.returnCacheDataElseLoad,timeoutInterval:20);request.setValue("iOS-Blog-Reader/1.0",forHTTPHeaderField:"User-Agent");guard let data=URLCache.shared.cachedResponse(for:request)?.data else{return nil};return try? JSONDecoder().decode([WordPressArticle].self,from:data)}
    var visibleArticles:[WordPressArticle]{guard !searchText.isEmpty else{return articles};return articles.filter{$0.titleText.localizedCaseInsensitiveContains(searchText)||$0.excerptText.localizedCaseInsensitiveContains(searchText)}}
    func fetchInitial()async{await fetchFirstPage()}
    func refresh()async{await fetchFirstPage()}
    private func fetchFirstPage()async{
        guard !isLoading else{return};isLoading=true;errorMessage=nil
        defer{isLoading=false}
        do{let result=try await service.fetchArticles(forceRefresh:true);articles=result;page=1;hasMore=result.count==10;hasLoadedOnce=true;animationTrigger &+= 1;saveCache()}catch{errorMessage=error.localizedDescription}
    }
    func loadMoreIfNeeded(after article:WordPressArticle)async{
        guard article.id==articles.last?.id,hasMore,!isLoadingMore,!isLoading else{return};isLoadingMore=true
        defer{isLoadingMore=false}
        do{let next=try await service.fetchArticles(page:page+1);articles.append(contentsOf:next);page+=1;hasMore=next.count==10;saveCache()}catch{}
    }
    func clearCacheState(){articles=[];page=1;hasMore=true;hasLoadedOnce=false;errorMessage=nil;searchText=""}
    private func saveCache(){let cache=CachedFeed(articles:articles,page:page,hasMore:hasMore);if let data=try? JSONEncoder().encode(cache){UserDefaults.standard.set(data,forKey:AppCache.articleFeedKey)}}
}
