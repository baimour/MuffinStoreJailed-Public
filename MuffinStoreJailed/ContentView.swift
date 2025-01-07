//
//  ContentView.swift
//  MuffinStoreJailed
//
//  Created by Mineek on 26/12/2024.
//

import SwiftUI

struct HeaderView: View {
    var body: some View {
        VStack {
            Text("MuffinStore Jailed")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("by @mineekdev\n中文汉化🇨🇳: White")
                .font(.caption)
        }
    }
}

struct FooterView: View {
    var body: some View {
        VStack {
            VStack {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.red)
                Text("使用风险自负！")
                    .foregroundStyle(.yellow)
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.red)
            }
            Text("我对使用此工具造成的任何损坏、数据丢失或任何其他问题不承担责任")
                .font(.caption)
        }
    }
}

struct ContentView: View {
    @State var ipaTool: IPATool?
    
    @State var appleId: String = ""
    @State var password: String = ""
    @State var code: String = ""
    
    @State var isAuthenticated: Bool = false
    @State var isDowngrading: Bool = false
    
    @State var appLink: String = ""
    
    var body: some View {
        VStack {
            HeaderView()
            Spacer()
            if !isAuthenticated {
                VStack {
                    Text("登录App Store")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("您的凭据将直接发送给Apple")
                        .font(.caption)
                }
                TextField("Apple ID", text: $appleId)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .autocapitalization(.none)
                .disableAutocorrection(true)
                SecureField("密码", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                TextField("双重验证", text: $code)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                Button("登录") {
                    if appleId.isEmpty || password.isEmpty {
                        return
                    }
                    if code.isEmpty {
                        // we can just try to log in and it'll request a code, very scuffed tho.
                        ipaTool = IPATool(appleId: appleId, password: password)
                        ipaTool?.authenticate(requestCode: true)
                        return
                    }
                    let finalPassword = password + code
                    ipaTool = IPATool(appleId: appleId, password: finalPassword)
                    let ret = ipaTool?.authenticate()
                    isAuthenticated = ret ?? false
                }
                .padding()
                
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.yellow)
                    Text("您需要提供双重验证代码才能成功登录")
                }
            } else {
                if isDowngrading {
                    VStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                        Text("请稍等...")
                            .font(.headline)
                            .fontWeight(.bold)
                        Text("该应用正在降级，这可能需要一段时间")
                            .font(.caption)
                        
                        Button("完成 (退出应用)") {
                            exit(0) // scuffed
                        }
                        .padding()
                    }
                } else {
                    VStack {
                        Text("降级应用程序")
                            .font(.headline)
                            .fontWeight(.bold)
                        Text("输入要降级的应用App Store链接")
                            .font(.caption)
                    }
                    TextField("应用分享链接", text: $appLink)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    Button("降级") {
                        if appLink.isEmpty {
                            return
                        }
                        var appLinkParsed = appLink
                        appLinkParsed = appLinkParsed.components(separatedBy: "id").last ?? ""
                        for char in appLinkParsed {
                            if !char.isNumber {
                                appLinkParsed = String(appLinkParsed.prefix(upTo: appLinkParsed.firstIndex(of: char)!))
                                break
                            }
                        }
                        print("应用ID: \(appLinkParsed)")
                        isDowngrading = true
                        downgradeApp(appId: appLinkParsed, ipaTool: ipaTool!)
                    }
                    .padding()

                    Button("注销并退出") {
                        isAuthenticated = false
                        EncryptedKeychainWrapper.nuke()
                        EncryptedKeychainWrapper.generateAndStoreKey()
                        sleep(3)
                        exit(0) // scuffed
                    }
                    .padding()
                }
            }
            Spacer()
            FooterView()
        }
        .padding()
        .onAppear {
            isAuthenticated = EncryptedKeychainWrapper.hasAuthInfo()
            print("在钥匙串中找到\(isAuthenticated ? "授权" : "未授权")信息")
            if isAuthenticated {
                guard let authInfo = EncryptedKeychainWrapper.getAuthInfo() else {
                    print("从钥匙串获取验证信息失败，正在退出登录")
                    isAuthenticated = false
                    EncryptedKeychainWrapper.nuke()
                    EncryptedKeychainWrapper.generateAndStoreKey()
                    return
                }
                appleId = authInfo["appleId"]! as! String
                password = authInfo["password"]! as! String
                ipaTool = IPATool(appleId: appleId, password: password)
                let ret = ipaTool?.authenticate()
                print("已重新验证\(ret! ? "成功" : "失败")")
            } else {
                print("在钥匙链中找不到身份验证信息，正在通过在SEP中生成密钥进行设置")
                EncryptedKeychainWrapper.generateAndStoreKey()
            }
        }
    }
}

#Preview {
    ContentView()
}
