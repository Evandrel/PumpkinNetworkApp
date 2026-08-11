import SwiftUI
import WebKit
struct ArticlesView:View{
    @StateObject private var viewModel=ArticlesViewModel()
    var body:some View{
        NavigationStack{
            Group{
                if viewModel.isLoading&&viewModel.articles.isEmpty{ProgressView("Loading articles…")}
                else if let error=viewModel.errorMessage,viewModel.articles.isEmpty{ContentUnavailableView("Couldn't Load Articles",systemImage:"wifi.exclamationmark",description:Text(error)).overlay(alignment:.bottom){Button("Try Again"){Task{await viewModel.fetchInitial()}}.buttonStyle(.borderedProminent).tint(.green).padding()}}
                else if !viewModel.hasLoadedOnce{ContentUnavailableView{Label("Get Articles",systemImage:"newspaper.fill")}description:{Text("Articles have not been downloaded on this device yet.")}actions:{Button("Get Articles"){Task{await viewModel.fetchInitial()}}.buttonStyle(.borderedProminent).tint(.green)}}
                else if viewModel.articles.isEmpty{ContentUnavailableView("No Articles",systemImage:"newspaper",description:Text("The website did not return any articles."))}
                else if viewModel.visibleArticles.isEmpty{ContentUnavailableView.search(text:viewModel.searchText)}
                else{articleList}
            }
            .navigationTitle("Articles")
            .searchable(text:$viewModel.searchText,prompt:"Search articles")
            .toolbar{ToolbarItem(placement:.topBarLeading){Button{Task{await viewModel.refresh()}}label:{Image(systemName:"arrow.clockwise")}.disabled(viewModel.isLoading).accessibilityLabel("Refresh articles")};ToolbarItem(placement:.topBarTrailing){Link(destination:URL(string:"https://www.pcl2.top")!){Image(systemName:"safari")}.accessibilityLabel("Open pcl2.top")}}
        }
        .onReceive(NotificationCenter.default.publisher(for:AppCache.didClearNotification)){_ in viewModel.clearCacheState()}
    }
    private var articleList:some View{
        ZStack{
            Color(uiColor:.systemBackground).ignoresSafeArea()
            ScrollView{
                LazyVStack(alignment:.leading,spacing:0){
                    Text("Latest Articles").font(.footnote.weight(.semibold)).foregroundStyle(.secondary).padding(.horizontal,20).padding(.top,12).padding(.bottom,8)
                    ForEach(Array(viewModel.visibleArticles.enumerated()),id:\.element.id){index,article in
                        VStack(spacing:0){NavigationLink{ArticleDetailView(summary:article)}label:{ArticleRow(article:article).padding(.horizontal,20).frame(maxWidth:.infinity,alignment:.leading).contentShape(Rectangle())}.buttonStyle(.plain).frame(maxWidth:.infinity,alignment:.leading).onAppear{Task{await viewModel.loadMoreIfNeeded(after:article)}};Divider().padding(.leading,82)}.modifier(ArticleRevealAnimation(trigger:viewModel.animationTrigger,index:index))
                    }
                    if viewModel.isLoadingMore{ProgressView().frame(maxWidth:.infinity).padding()}
                }
                .frame(maxWidth:.infinity,alignment:.leading)
            }
            .frame(maxWidth:.infinity,maxHeight:.infinity)
            .refreshable{await viewModel.refresh()}
        }
        .frame(maxWidth:.infinity,maxHeight:.infinity)
    }
}
private struct ArticleRevealAnimation:ViewModifier{
    let trigger:Int
    let index:Int
    @State private var isVisible=false
    func body(content:Content)->some View{content.opacity(isVisible ? 1:0).offset(y:isVisible ? 0:14).task(id:trigger){isVisible=false;do{try await Task.sleep(nanoseconds:UInt64(min(index,12))*40_000_000)}catch{return};withAnimation(.smooth(duration:0.38)){isVisible=true}}}
}
private struct ArticleRow:View{
    let article:WordPressArticle
    var body:some View{
        HStack(alignment:.top,spacing:10){
            ZStack{RoundedRectangle(cornerRadius:11,style:.continuous).fill(LinearGradient(colors:[.green.opacity(0.8),.cyan.opacity(0.55)],startPoint:.topLeading,endPoint:.bottomTrailing));Image(systemName:"doc.richtext.fill").font(.title2).foregroundStyle(.white)}.frame(width:52,height:52)
            VStack(alignment:.leading,spacing:3){Text(article.titleText).font(.headline).lineLimit(2);Text(article.dateText).font(.caption).foregroundStyle(.secondary);if !article.excerptText.isEmpty{Text(article.excerptText).font(.subheadline).foregroundStyle(.secondary).lineLimit(2)}}.frame(maxWidth:.infinity,alignment:.leading)
        }.padding(.vertical,4)
    }
}
private struct ArticleDetailView:View{
    let summary:WordPressArticle
    @State private var article:WordPressArticle?
    @State private var errorMessage:String?
    var body:some View{
        Group{if let article{ArticleWebView(article:article)}else if let errorMessage{ContentUnavailableView("Couldn't Open Article",systemImage:"doc.badge.exclamationmark",description:Text(errorMessage))}else{ProgressView("Loading article…")}}
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{ToolbarItem(placement:.topBarTrailing){ShareLink(item:summary.link){Image(systemName:"square.and.arrow.up")}}}
            .task{await load()}
    }
    private func load()async{do{article=try await WordPressService().fetchArticle(id:summary.id)}catch{errorMessage=error.localizedDescription}}
}
private struct ArticleWebView:UIViewRepresentable{
    let article:WordPressArticle
    func makeCoordinator()->Coordinator{Coordinator()}
    func makeUIView(context:Context)->WKWebView{let config=WKWebViewConfiguration();config.defaultWebpagePreferences.allowsContentJavaScript = false;let view=WKWebView(frame:.zero,configuration:config);view.navigationDelegate=context.coordinator;view.isOpaque = false;view.backgroundColor = .clear;view.scrollView.backgroundColor = .clear;return view}
    func updateUIView(_ view:WKWebView,context:Context){let html=document;if context.coordinator.html != html{context.coordinator.html=html;view.loadHTMLString(html,baseURL:URL(string:"https://www.pcl2.top"))}}
    private var document:String{
        """
        <!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1"><style>:root{color-scheme:light dark}body{font-family:-apple-system,BlinkMacSystemFont,sans-serif;margin:0 auto;padding:18px;max-width:760px;line-height:1.65;color:#202124;background:transparent}h1{font-size:2rem;line-height:1.15;margin:8px 0}h2{font-size:1.45rem;margin-top:1.6em}h3{font-size:1.2rem;margin-top:1.4em}.meta{color:#6e6e73;font-size:.85rem;margin-bottom:24px}img{display:block;max-width:100%;height:auto;border-radius:14px;margin:18px auto}figure{margin:18px 0}figcaption{color:#6e6e73;font-size:.8rem;text-align:center}a{color:#20a35a}pre{overflow:auto;padding:14px;border-radius:12px;background:rgba(128,128,128,.13)}code{font-family:ui-monospace,monospace;background:rgba(128,128,128,.12);padding:2px 5px;border-radius:5px}blockquote{margin:18px 0;padding:2px 16px;border-left:4px solid #2eaf65;background:rgba(46,175,101,.08)}@media(prefers-color-scheme:dark){body{color:#f2f2f7}}</style></head><body><h1>\(article.titleText)</h1><div class="meta">\(article.dateText) · pcl2.top</div>\(article.content?.rendered ?? "")</body></html>
        """
    }
    final class Coordinator:NSObject,WKNavigationDelegate{var html="";func webView(_ webView:WKWebView,decidePolicyFor navigationAction:WKNavigationAction,decisionHandler:@escaping(WKNavigationActionPolicy)->Void){if navigationAction.navigationType == .linkActivated,let url=navigationAction.request.url{UIApplication.shared.open(url);decisionHandler(.cancel)}else{decisionHandler(.allow)}}}
}
