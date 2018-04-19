//
//  ViewController.swift
//  SwiftWKWebView
//
//  Created by guangwei li on 2018/4/10.
//  Copyright © 2018年 guangwei li. All rights reserved.
//https://www.jianshu.com/p/7bb5f15f1daa
//http://www.cnblogs.com/fengmin/p/5737355.html

//https://www.jianshu.com/p/ac45d99cf912

import UIKit
import WebKit

import CFNetwork

class ViewController: UIViewController {
    
    var webView:WKWebView?
    var progressView:UIProgressView?

    var userVC:WKUserContentController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        creatProgressView()
        
        let c = WKWebViewConfiguration.init()
        //设置是否将网页内容全部加载到内存后再渲染
        c.suppressesIncrementalRendering = false
        //设置HTML5视频是否允许网页播放 设置为NO则会使用本地播放器
        c.allowsInlineMediaPlayback = true
        //设置是否允许ariPlay播放
        c.allowsAirPlayForMediaPlayback = true
        //设置视频是否需要用户手动播放  设置为NO则会允许自动播放 iOS9后弃用
//        c.mediaPlaybackRequiresUserAction = false
        //确定哪些媒体类型需要用户手势才能开始播放
        c.mediaTypesRequiringUserActionForPlayback = .video
        //设置选择模式 是按字符选择 还是按模块选择
        /*
         typedef NS_ENUM(NSInteger, WKSelectionGranularity) {
         //按模块选择
         WKSelectionGranularityDynamic,
         //按字符选择
         WKSelectionGranularityCharacter,
         } NS_ENUM_AVAILABLE_IOS(8_0);
         */
        c.selectionGranularity = .character
        //设置请求的User-Agent信息中应用程序名称 iOS9后可用
        c.applicationNameForUserAgent = "HS"
        
        
        let p = WKPreferences()//偏好设置
        p.javaScriptEnabled =  true//是否支持javascript
        p.javaScriptCanOpenWindowsAutomatically = true ////不通过用户交互，是否可以打开窗口
        p.minimumFontSize = 10//最小字体大小 当将javaScriptEnabled属性设置为NO时，可以看到明显的效果
    
        c.preferences = p
        //进程池
        let runloop = WKProcessPool()
        
        c.processPool = runloop
        
        //通过JS与webView内容交互
        let uservc = WKUserContentController()
        // 注入JS对象名称senderModel，当JS通过senderModel来调用时，我们可以在WKScriptMessageHandler代理中接收到
        uservc.add(self, name: "senderModel")//需移除
        
        userVC = uservc
        c.userContentController = uservc
        
        
        let w = WKWebView.init(frame: CGRect.init(x: 0, y: 88, width: view.bounds.width, height: view.bounds.height), configuration: c)
        
        w.allowsLinkPreview = true
        w.allowsBackForwardNavigationGestures = true
      //  let fi = WKFrameInfo.init()
        w.navigationDelegate = self
        w.uiDelegate  = self
        webView = w
        
        
        let path = Bundle.main.url(forResource: "WKWebViewText", withExtension: "html")
        guard let getpath = path else {
            return
        }
        let request = URLRequest.init(url: getpath)
        w.load(request)
        
        
        view.addSubview(w)
        
        
        ///监听进度
        w.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
        w.addObserver(self, forKeyPath: "loading", options: .new, context: nil)
        w.addObserver(self, forKeyPath: "title", options: .new, context: nil)
        
        
        
        
    }
    func creatProgressView(){
        self.progressView = UIProgressView.init(progressViewStyle: .default)
        progressView?.frame = CGRect.init(x: 0, y: 88, width: view.bounds.width, height: 10)
        progressView?.backgroundColor = UIColor.green
        view.addSubview(progressView!)
    }
    //KVO-监听
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "title" {
           self.title = webView?.title
        }else if keyPath == "loading"{
            print("loading")
        }else if keyPath == "estimatedProgress"{
            
            guard let progress = webView?.estimatedProgress else{
                return
            }
            //estimatedProgress取值范围是0-1
            progressView?.progress = Float(progress)
        }
        
        
        if !(webView?.isLoading)! {
            UIView.animate(withDuration: 0.5, animations: {
                self.progressView?.alpha = 0
            })
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    deinit {
        userVC?.removeScriptMessageHandler(forName: "senderModel")
        webView?.removeObserver(self, forKeyPath: "estimatedProgress")
        webView?.removeObserver(self, forKeyPath: "loading")
        webView?.removeObserver(self, forKeyPath: "title")
        
    }
}

extension ViewController:WKNavigationDelegate,WKUIDelegate,WKScriptMessageHandler{
    /*****************WKScriptMessageHandler************/
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        //这里可以通过name处理多组交互
        if message.name == "senderModel" {
            print("sender=====\(message.body)")
            let p = message.body
            
        }
    }
    
    /*************WKNavigationDelegate**********************/
    //*****/该代理提供的方法，可以用来追踪加载过程（页面开始加载，加载完成，加载失败），决定是否执行跳转
    //页面开始加载时调用
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        let url = webView.url
        print(url)
    }
    
    //当内容开始返回时调用
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        
    }
    //页面加载完成之后调用
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let title = webView.title
        //OC传值给JS
        //原生调用H5方法
        webView.evaluateJavaScript("callJsConfirm()", completionHandler: {(result,error) in
            if (error != nil){
                print("failed==\(error.debugDescription)")
            }else{
                print("success")
            }
        })
    }
    //页面加载失败时调用,提交发生错误时调用
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        
    }
    //主页数据加载发生错误时调用
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        
    }
    //进程被终止时调用
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        
    }
    
    
    //*********/页面跳转的代理方法有三种，分为（收到跳转与决定是否跳转两种）
    //接收到服务器跳转请求之后调用
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        
    }
    //在收到响应后决定是否跳转,如果设置为不允许响应，web内容就不会传过来
    //接收到数据后是否允许执行渲染
    /*
     其中，WKNavigationResponse为请求回执信息
     WKNavigationResponsePokicy为开发者回执，枚举如下：
     typedef NS_ENUM(NSInteger, WKNavigationResponsePolicy) {
     //取消渲染
     WKNavigationResponsePolicyCancel,
     //允许渲染
     WKNavigationResponsePolicyAllow,
     } NS_ENUM_AVAILABLE(10_10, 8_0);
     */
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(.allow)
    }
    //在发送请求之前决定是否跳转
    /*
     决定是否响应网页的某个动作，例如加载，回退，前进，刷新等，在这个方法中，必须执行decisionHandler()代码块，并将是否允许这个活动执行在block中进行传入
     */
    /*
     WKNavigationAction是网页动作的抽象化，其中封装了许多行为信息，后面会介绍
     WKNavigationActionPolicy为开发者回执，枚举如下：
     typedef NS_ENUM(NSInteger, WKNavigationActionPolicy) {
     //取消此次行为
     WKNavigationActionPolicyCancel,
     //允许此次行为
     WKNavigationActionPolicyAllow,
     } NS_ENUM_AVAILABLE(10_10, 8_0);
     */
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        //原页面
        let sourceF = navigationAction.sourceFrame
        
        //目标页面
        let targetf = navigationAction.targetFrame
        
        //请求url
        let url = navigationAction.request
        //活动类型
        /*
        typedef NS_ENUM(NSInteger, WKNavigationType) {
            //链接激活
            WKNavigationTypeLinkActivated,
            //提交操作
            WKNavigationTypeFormSubmitted,
            //前进操作
            WKNavigationTypeBackForward,
            //刷新操作
            WKNavigationTypeReload,
            //重提交操作 例如前进 后退 刷新
            WKNavigationTypeFormResubmitted,
            //其他类型
            WKNavigationTypeOther = -1,
        } NS_ENUM_AVAILABLE(10_10, 8_0);
         */
        let type = navigationAction.navigationType
        
        
        
        let hostname = navigationAction.request.url?.host?.lowercased() ?? ""
        print("HostName==\(hostname)")
        if navigationAction.navigationType == .linkActivated && hostname.contains(".baidu.com"){
            if UIApplication.shared.canOpenURL(navigationAction.request.url!){
//                let options = [UIApplicationOpenURLOptionUniversalLinksOnly:true]
                let openUrl = navigationAction.request.url
                // 对于跨域，需要手动跳转
                UIApplication.shared.open(openUrl!, options: [:], completionHandler: nil)
            }
            
            // 不允许web内跳转
            decisionHandler(.cancel)
        }else{
            self.progressView?.alpha = 1
            decisionHandler(.allow)
        }
        print("=====\(url)")
        
        
       
    }
    //需要响应身份验证时调用 同样在block中需要传入用户身份凭证
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        //用户身份信息
        let newCard = URLCredential.init(user: "", password: "", persistence: .none)
        // 为 challenge 的发送方提供 credential
        challenge.sender?.use(newCard, for: challenge)
        completionHandler(.useCredential,newCard)
    }
    
    /********************WKUIDelegate**********************/
    
    
//    //创建一个新的WebView
//    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
//        return webView
//    }
    //关闭webView时调用的方法
    func webViewDidClose(_ webView: WKWebView) {
        
    }
    //*******/交互JavaScript的方法
    //JavaScript调用alert方法后回调的方法 message中为alert提示的信息 必须要在其中调用completionHandler()
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        
        let alert = UIAlertController.init(title: "提示", message: "提示信息", preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "OK", style: .default, handler: {action in
            completionHandler()
        }))
        present(alert, animated: true, completion: nil)
        
        print("\(message)")
        
    }
    //JavaScript调用confirm方法后回调的方法 confirm是js中的确定框，需要在block中把用户选择的情况传递进去
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController.init(title: "提示", message: "提示信息", preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "OK", style: .default, handler: {action in
            completionHandler(true)
        }))
        alert.addAction(UIAlertAction.init(title: "cancel", style: .cancel, handler: {cancel in
            completionHandler(false)
        }))
        
        present(alert, animated: true, completion: nil)
        
        print("\(message)")
        
        
    }
    //JavaScript调用prompt方法后回调的方法 prompt是js中的输入框 需要在block中把用户输入的信息传入
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        
        let alert = UIAlertController.init(title: "提示", message: "提示信息", preferredStyle: .alert)
        alert.addTextField(configurationHandler: {textfield in
            textfield.textColor = UIColor.black
        })
        alert.addAction(UIAlertAction.init(title: "OK", style: .default, handler: {action in
             completionHandler(alert.textFields?.last?.text)
        }))
        present(alert, animated: true, completion: nil)
        
        
       
    }
    
    
}



