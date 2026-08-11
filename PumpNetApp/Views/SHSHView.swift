import SwiftUI

struct SHSHView:View{
    @StateObject private var viewModel=SHSHViewModel()
    @FocusState private var isECIDFocused:Bool
    @State private var showingHistory=false
    var body:some View{
        ScrollView{
            VStack(spacing:20){
                VStack(spacing:10){Text("SHSH2 Checker").font(.title.bold());Text("Enter a device ECID to see which SHSH blobs are available.").font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)}
                VStack(alignment:.leading,spacing:10){
                    HStack{Image(systemName:"number").foregroundStyle(.secondary);TextField("",text:$viewModel.ecid).keyboardType(.numberPad).textInputAutocapitalization(.never).autocorrectionDisabled().focused($isECIDFocused).onSubmit(search);if !viewModel.ecid.isEmpty{Button{viewModel.ecid=""}label:{Image(systemName:"xmark.circle.fill").foregroundStyle(.tertiary)}.accessibilityLabel("Clear ECID")}}
                        .padding(.horizontal,14).frame(height:50).background(.thinMaterial,in:RoundedRectangle(cornerRadius:14,style:.continuous))
                    Button(action:search){Group{if viewModel.isLoading{ProgressView()}else{Label("Check SHSH",systemImage:"magnifyingglass")}}.fontWeight(.semibold).frame(maxWidth:.infinity).frame(height:48)}.buttonStyle(.borderedProminent).tint(.green).disabled(!viewModel.canSearch)
                    Text("Plug is provided by JJR.ONE. https://www.jjr.one/i4tool/api/requestBackupSHSHList.php?ecid=[ecid]&model=all").font(.caption).foregroundStyle(.secondary)
                }
                if let error=viewModel.errorMessage{Label(error,systemImage:"exclamationmark.triangle.fill").foregroundStyle(.red).frame(maxWidth:.infinity,alignment:.leading).padding().background(.red.opacity(0.08),in:RoundedRectangle(cornerRadius:14))}
                else if viewModel.didSearch{VStack(alignment:.leading,spacing:12){HStack{Text("Available SHSH").font(.headline);Spacer();Text("\(viewModel.results.count)").font(.headline.monospacedDigit()).foregroundStyle(.secondary)};if viewModel.results.isEmpty{Text("No saved SHSH blobs were found for this ECID.").foregroundStyle(.secondary).frame(maxWidth:.infinity,alignment:.leading).padding(.vertical,12)}else{ForEach(viewModel.results,id:\.self){version in HStack(spacing:12){Image(systemName:"checkmark.circle.fill").foregroundStyle(.green);Text(version).font(.body.monospaced());Spacer()}.padding(.vertical,4)}};if !viewModel.serverMessage.isEmpty{Text(viewModel.serverMessage).font(.caption).foregroundStyle(.secondary)}}.padding().background(.thinMaterial,in:RoundedRectangle(cornerRadius:16,style:.continuous))}
            }
            .padding(20).frame(maxWidth:620).frame(maxWidth:.infinity)
        }
        .background(Color(uiColor:.systemGroupedBackground)).navigationTitle("SHSH2 Checker").navigationBarTitleDisplayMode(.inline)
        .toolbar{ToolbarItem(placement:.topBarTrailing){Button{showingHistory=true}label:{Image(systemName:"clock.arrow.circlepath")}.accessibilityLabel("SHSH search history")}}
        .sheet(isPresented:$showingHistory){SearchHistoryView(title:"SHSH History",systemImage:"checkmark.shield",history:viewModel.history){ecid in isECIDFocused=false;Task{await viewModel.search(ecid:ecid)}}onClear:{viewModel.clearHistory()}}
        .animation(.snappy,value:viewModel.didSearch).animation(.snappy,value:viewModel.isLoading)
    }
    private func search(){isECIDFocused=false;Task{await viewModel.search()}}
}

#Preview{NavigationStack{SHSHView()}}
