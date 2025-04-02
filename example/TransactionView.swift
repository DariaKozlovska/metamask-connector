//
//  TransactionView.swift
//  metamask-ios-sdk_Example
//

import SwiftUI
import Combine
import metamask_ios_sdk
import Foundation
import BigInt

@MainActor
struct TransactionView: View {
    @EnvironmentObject var metamaskSDK: MetaMaskSDK

    @State private var decimalValue = "0.001"
    @State private var hexValue = "0x1"
    @State var result: String = ""
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var to = "0x0000000000000000000000000000000000000000"
    @State var isConnectWith: Bool = false
    @State private var sendTransactionTitle = "Send Transaction"
    @State private var connectWithSendTransactionTitle = "Connect & Send Transaction"

    @State private var showProgressView = false

    var body: some View {
        Form {
            Section {
                Text("From")
                TextField("Enter sender address", text: $metamaskSDK.account)
                    .frame(minHeight: 32)
            }

            Section {
                Text("To")
                TextEditor(text: $to)
                    .frame(minHeight: 32)
            }

            Section {
                Text("Value")
                TextField("Value", text: $decimalValue)
                    .frame(minHeight: 32)
                    .keyboardType(.decimalPad)
                    .onChange(of: decimalValue) { newValue in
                        convertDecimalToHex()
                    }
            }

//            Section {
//                Text("Result")
//                Text(result)
//                    .frame(minHeight: 40)
//            }

            Section {
                ZStack {
                    Button {
                        Task {
                            await sendTransaction()
                        }
                    } label: {
                        Text(isConnectWith ? connectWithSendTransactionTitle : sendTransactionTitle)
                            .frame(maxWidth: .infinity, maxHeight: 32)
                    }
                    .alert(isPresented: $showError) {
                        Alert(
                            title: Text("Error"),
                            message: Text(errorMessage)
                        )
                    }

                    if showProgressView {
                        ProgressView()
                            .scaleEffect(1.5, anchor: .center)
                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                    }
                }
            }
        }
    }
    
    private func convertDecimalToHex() {
        // Remove any non-numeric characters except decimal point
        let filtered = decimalValue.filter { "0123456789.".contains($0) }
        let decimalString = filtered == decimalValue ? decimalValue : filtered
        
        // Ensure we don't have multiple decimal points
        let components = decimalString.components(separatedBy: ".")
        if components.count > 2 {
            decimalValue = String(decimalString.dropLast())
            return
        }
        
        // Convert to wei (1 ETH = 10^18 wei)
        if let decimal = Decimal(string: decimalString) {
            let weiMultiplier = Decimal(sign: .plus, exponent: 18, significand: 1)
            let weiValue = decimal * weiMultiplier
            
            // Convert to BigInt to handle large numbers
            if let weiInt = BigInt(weiValue.description) {
                hexValue = "0x" + String(weiInt, radix: 16)
            }
        }
    }

    func sendTransaction() async {
        let transaction = Transaction(
            to: to,
            from: metamaskSDK.account,
            value: hexValue
        )

        let parameters: [Transaction] = [transaction]

        let transactionRequest = EthereumRequest(
            method: .ethSendTransaction,
            params: parameters // eth_sendTransaction rpc call expects an array parameters object
        )

        showProgressView = true

        let transactionResult = isConnectWith
        ? await metamaskSDK.connectWith(transactionRequest)
        : await metamaskSDK.sendTransaction(from: metamaskSDK.account, to: to, value: hexValue)

        showProgressView = false

        switch transactionResult {
        case let .success(value):
            result = value
        case let .failure(error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

struct Transaction: CodableData {
    let to: String
    let from: String
    let value: String
    let data: String?

    init(to: String, from: String, value: String, data: String? = nil) {
        self.to = to
        self.from = from
        self.value = value
        self.data = data
    }

    func socketRepresentation() -> NetworkData {
        var dict: [String: Any] = [
            "to": to,
            "from": from,
            "value": value
        ]
        if let data = data { dict["data"] = data }
        return dict
    }
}

struct TransactionView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionView()
    }
}
