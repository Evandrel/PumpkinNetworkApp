import Foundation

struct SHSHService{
    private let endpoint=URL(string:"https://www.jjr.one/i4tool/api/requestBackupSHSHList.php")!
    func fetch(ecid:String)async throws->SHSHResponse{
        var components=URLComponents(url:endpoint,resolvingAgainstBaseURL:false)
        components?.queryItems=[URLQueryItem(name:"ecid",value:ecid),URLQueryItem(name:"model",value:"all")]
        guard let url=components?.url else{throw SHSHServiceError.invalidResponse}
        var request=URLRequest(url:url);request.timeoutInterval=20;request.cachePolicy = .reloadIgnoringLocalCacheData
        let(data,response)=try await URLSession.shared.data(for:request)
        guard let http=response as? HTTPURLResponse,(200...299).contains(http.statusCode)else{throw SHSHServiceError.invalidResponse}
        do{return try JSONDecoder().decode(SHSHResponse.self,from:data)}catch{throw SHSHServiceError.invalidResponse}
    }
}
