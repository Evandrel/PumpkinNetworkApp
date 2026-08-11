import Foundation

struct SHSHResponse:Decodable{
    let status:String
    let message:String
    let data:[String]
    private enum CodingKeys:String,CodingKey{case status,message,data}
    init(from decoder:Decoder)throws{let container=try decoder.container(keyedBy:CodingKeys.self);status=try container.decodeIfPresent(String.self,forKey:.status) ?? "";message=try container.decodeIfPresent(String.self,forKey:.message) ?? "";data=(try? container.decode([String].self,forKey:.data)) ?? []}
}

enum SHSHServiceError:LocalizedError{
    case invalidResponse
    case server(String)
    var errorDescription:String?{switch self{case .invalidResponse:return "The SHSH server returned an invalid response.";case .server(let message):return message.isEmpty ? "The lookup failed.":message}}
}
