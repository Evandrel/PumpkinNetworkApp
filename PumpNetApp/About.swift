//
//  About.swift
//  PumpNet App
//
//  Created by xmwpumpkin on 8/10/26.
//  ？
import SwiftUI
struct About:View{
    
    @State private var pumpkinNetworkAppText = ""
    @State private var versionText = ""
    private var appVersion:String{Bundle.main.object(forInfoDictionaryKey:"CFBundleShortVersionString")as? String ?? "Unknown"}
    var body:some View{
        NavigationStack{
            VStack(spacing:8){
                Image(systemName:"info.circle.fill")
                    .font(.system(size:64))
                    .foregroundStyle(.green)
                
                Text("About")
                    .font(.largeTitle.bold())
                
                Group{
                    Text("\(pumpkinNetworkAppText)")
                        .font(.custom("Georgia", size: 36))
                        .multilineTextAlignment(.center)
                        .contentTransition(.numericText())
                        .onAppear() {
                            withAnimation(.smooth) {
                                pumpkinNetworkAppText = "The Pumpkin Network App"
                            }
                        }
                        .onDisappear {
                            pumpkinNetworkAppText = ""
                        }
                    Text("\(versionText)")
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())
                        .onAppear() {
                            withAnimation(.smooth(duration: 10)) {
                                versionText = "Version \(appVersion)\n Insider Beta"
                            }
                        }
                        .onDisappear {
                            pumpkinNetworkAppText = ""
                        }
                }
            }
            .padding()
            .navigationTitle("About")
        }
    }
}
#Preview{
    About()
}
