//
//  ConnectView.swift
//  metamask-ios-sdk_Example
//

import SwiftUI
import metamask_ios_sdk

extension Notification.Name {
    static let Event = Notification.Name("event")
    static let Connection = Notification.Name("connection")
}

private let DAPP_SCHEME = "dubdapp"

@MainActor
struct ContentView: View {

    // We recommend adding support for Infura API for read-only RPCs (direct calls) via SDKOptions
    @ObservedObject var metaMaskSDK = MetaMaskSDK.shared(
        AppMetadata(
            name: "Example Wallet Metamask",
            url: "https://example-wallet-metamask.com"),
        transport: .socket,
        sdkOptions: nil
        )

    @State private var connected: Bool = false
    @State private var status: String = "Offline"

    @State private var errorMessage = ""
    @State private var showError = false

    @State private var connectAndSignResult = ""
    @State private var isConnect = true
    @State private var isConnectAndSign = false
    @State private var isConnectWith = false

    @State private var showProgressView = false

    var body: some View {
        NavigationView {
            List {
                Section {
                    Group {
                        HStack {
                            Text("Status")
                                .bold()
                            Spacer()
                            Text(status)
                        }

                        HStack {
                            Text("Chain ID")
                                .bold()
                            Spacer()
                            Text(metaMaskSDK.chainId)
                        }

                        HStack {
                            Text("Account")
                                .bold()
                            Spacer()
                            Text(shortenAddress(metaMaskSDK.account))
                        }
                    }
                }
                
                if !metaMaskSDK.account.isEmpty {
                    Section {
                        Group {
                            NavigationLink("Transact") {
                                TransactionView().environmentObject(metaMaskSDK)
                            }

                        }
                    }
                }

                if metaMaskSDK.account.isEmpty {
                    Button(action: {
                        Task { await connectSDK() }
                    }) {
                        Text("Connect to MetaMask")
                            .frame(maxWidth: .infinity, maxHeight: 44)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding()
                    .alert(isPresented: $showError) {
                        Alert(title: Text("Error"), message: Text(errorMessage))
                    }
                } else {
                    HStack {
                        Button(action: {
                            metaMaskSDK.clearSession()
                        }) {
                            Text("Clear Session")
                                .frame(maxWidth: .infinity, maxHeight: 44)
                                .background(Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        
                        Button(action: {
                            Task { await disconnectSDK() }
                        }) {
                            Text("Disconnect")
                                .frame(maxWidth: .infinity, maxHeight: 44)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                }
            }
        }
    }

    func connectSDK() async {
        metaMaskSDK.clearSession()
        
        showProgressView = true
        let result = await metaMaskSDK.connect()
        showProgressView = false

        switch result {
        case .success:
            status = "Online"
        case let .failure(error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func shortenAddress(_ address: String) -> String {
        guard address.count > 8 else { return address }
        let start = address.prefix(4)
        let end = address.suffix(4)
        return "\(start)...\(end)"
    }
    
    func disconnectSDK() async {
        print("Disconnecting from MetaMask...")
        metaMaskSDK.clearSession()  // Czyści dane lokalne
        await metaMaskSDK.disconnect() // Próbuje odłączyć MetaMaska
        status = "Offline"
    }

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
