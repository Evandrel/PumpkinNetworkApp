import Foundation
import UIKit
struct WordPressArticle:Codable,Identifiable,Hashable{
    struct Rendered:Codable,Hashable{let rendered:String}
    let id:Int
    let date:String
    let link:URL
    let title:Rendered
    let excerpt:Rendered?
    let content:Rendered?
    var titleText:String{title.rendered.plainHTML}
    var excerptText:String{excerpt?.rendered.plainHTML.replacingOccurrences(of:"[…]",with:"") ?? ""}
    var publishedAt:Date?{ISO8601DateFormatter().date(from:date+"Z")}
    var dateText:String{publishedAt?.formatted(date:.abbreviated,time:.omitted) ?? String(date.prefix(10))}
}
private extension String{
    var plainHTML:String{
        guard let data=("<meta charset=\"UTF-8\">"+self).data(using:.utf8),let value=try? NSAttributedString(data:data,options:[.documentType:NSAttributedString.DocumentType.html,.characterEncoding:String.Encoding.utf8.rawValue],documentAttributes:nil) else{return self}
        return value.string.replacingOccurrences(of:"\n",with:" ").replacingOccurrences(of:"  ",with:" ").trimmingCharacters(in:.whitespacesAndNewlines)
    }
}
