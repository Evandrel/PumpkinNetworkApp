import Foundation

@MainActor final class SHSHViewModel:ObservableObject{
    @Published var ecid=""
    @Published private(set)var results:[String]=[]
    @Published private(set)var isLoading=false
    @Published private(set)var didSearch=false
    @Published private(set)var serverMessage=""
    @Published private(set)var errorMessage:String?
    @Published private(set)var history:[String]=[]
    private let service:SHSHService
    private static let historyKey="shshSearchHistory.v1"
    init(service:SHSHService=SHSHService()){self.service=service;history=UserDefaults.standard.stringArray(forKey:Self.historyKey) ?? []}
    var canSearch:Bool{!ecid.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty && !isLoading}
    func search()async{
        let value=ecid.trimmingCharacters(in:.whitespacesAndNewlines)
        guard !value.isEmpty else{return}
        guard value.allSatisfy({"0123456789".contains($0)})else{errorMessage="ECID must contain numbers only.";didSearch=false;return}
        ecid=value;isLoading=true;didSearch=false;errorMessage=nil;serverMessage=""
        defer{isLoading=false}
        do{let response=try await service.fetch(ecid:value);guard response.status.lowercased()=="success"else{throw SHSHServiceError.server(response.message)};results=response.data;serverMessage=response.message;didSearch=true;recordHistory(value)}catch{results=[];errorMessage=error.localizedDescription}
    }
    func search(ecid selectedECID:String)async{ecid=selectedECID;await search()}
    func clearHistory(){history=[];UserDefaults.standard.removeObject(forKey:Self.historyKey)}
    private func recordHistory(_ ecid:String){history.removeAll{$0==ecid};history.insert(ecid,at:0);history=Array(history.prefix(20));UserDefaults.standard.set(history,forKey:Self.historyKey)}
}
