//so fucking hard tis shit i asked ai i cant figure out wtf these apis work


import Foundation
actor WordPressService{
    enum ServiceError:LocalizedError{case invalidResponse,server(Int);var errorDescription:String?{switch self{case .invalidResponse:"The website returned an unexpected response.";case .server(let code):"The website returned error \(code)."}}}
    private let baseURL=URL(string:"https://www.pcl2.top/wp-json/wp/v2")!
    private let session:URLSession
    init(session:URLSession = .shared){self.session=session}
    func fetchArticles(page:Int=1,forceRefresh:Bool=false)async throws->[WordPressArticle]{try await request(path:"posts",items:[.init(name:"page",value:String(page)),.init(name:"per_page",value:"10"),.init(name:"_fields",value:"id,date,link,title,excerpt")],forceRefresh:forceRefresh)}
    func fetchArticle(id:Int)async throws->WordPressArticle{try await request(path:"posts/\(id)",items:[.init(name:"_fields",value:"id,date,link,title,content")],forceRefresh:false)}
    private func request<T:Decodable>(path:String,items:[URLQueryItem],forceRefresh:Bool)async throws->T{
        var components=URLComponents(url:baseURL.appendingPathComponent(path),resolvingAgainstBaseURL:false)!
        components.queryItems=items
        var request=URLRequest(url:components.url!,cachePolicy:forceRefresh ? .reloadIgnoringLocalCacheData:.returnCacheDataElseLoad,timeoutInterval:20)
        request.setValue("iOS-Blog-Reader/1.0",forHTTPHeaderField:"User-Agent")
        if forceRefresh{request.setValue("no-cache",forHTTPHeaderField:"Cache-Control")}
        let(data,response)=try await session.data(for:request)
        guard let http=response as? HTTPURLResponse else{throw ServiceError.invalidResponse}
        guard(200...299).contains(http.statusCode)else{throw ServiceError.server(http.statusCode)}
        do{return try JSONDecoder().decode(T.self,from:data)}catch{throw ServiceError.invalidResponse}
    }
}
