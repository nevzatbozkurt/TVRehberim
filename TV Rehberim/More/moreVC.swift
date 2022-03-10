//
//  moreVC.swift
//  TV Rehberim
//
//  Created by Nevzat BOZKURT on 3.02.2019.
//  Copyright © 2019 Nevzat BOZKURT. All rights reserved.
//

import UIKit
import StoreKit
import MessageUI

class moreVC: UIViewController, UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate {


    let data = ["Uygulama Hakkında","Uygulamaya Puan Ver","Arkadaşınla Paylaş","Sorun Bildir", "İletişim"]
    let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String
    
    override func viewDidLoad() {
        super.viewDidLoad()
         self.automaticallyAdjustsScrollViewInsets = false //ios9 collectionview boslugu fixledi
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        if indexPath.row % 2 == 0 {
            cell.backgroundColor = UIColor(red:0.44, green:0.44, blue:0.47, alpha:1.0)
        } else {
            cell.backgroundColor = UIColor(red:0.44, green:0.44, blue:0.47, alpha:0.85)
        }
        cell.textLabel?.text = data[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.row {
        case 0:
            performSegue(withIdentifier: "aboutSegue", sender: self)
            
        case 1:
            
            
            let url = URL(string: myAppStoreUrl)!
            if #available( iOS 10.3,*){
                SKStoreReviewController.requestReview()
            } else {
                UIApplication.shared.openURL(url)
            }
            
            
        case 2:
            //Set the default sharing message.
            let link = NSURL(string: myAppStoreUrl)
            //Set the link to share.
            let msg = "TV Rehberim iOS Uygulaması"
            
            let objectsToShare = [msg as Any, link as Any]
           
  
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            self.present(activityVC, animated: true, completion: nil)
            if let popOver = activityVC.popoverPresentationController {
                popOver.sourceView = self.view
                //popOver.sourceRect =
                //popOver.barButtonItem
            }
            
            
            
        case 3:
            sendEmail(title: "Sorun Bildirimi (Tv Rehberim \(appVersion!))", body:"<br><br><hr>" +  UIDevice.current.modelName + " " + UIDevice.current.systemVersion)
        case 4:
            sendEmail(title: "İletişim (Tv Rehberim \(appVersion!))", body: "")
        default:
            return
        }
        
        
    }
    
  
    
    func sendEmail(title: String, body: String) {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients(["bozkurtnevzat@icloud.com"])
            mail.setSubject(title)
            mail.setMessageBody(body, isHTML: true)
            
            present(mail, animated: true)
        } else {
            let sendMailErrorAlert = UIAlertController(title: "Hata", message: "Cihazınız e-posta gönderemiyor. Lütfen e-posta yapılandırmasını kontrol edip tekrar deneyin.", preferredStyle: .alert)
            sendMailErrorAlert.addAction(UIAlertAction(title: "Tamam", style: UIAlertAction.Style.default, handler: nil))
            self.present(sendMailErrorAlert, animated: true, completion: nil)
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
    
    
    
}



extension UIDevice {
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
    
    
    
}
