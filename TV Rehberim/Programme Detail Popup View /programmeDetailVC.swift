//
//  programmeDetailVC.swift
//  TV Rehberim
//
//  Created by Nevzat BOZKURT on 31.01.2019.
//  Copyright © 2019 Nevzat BOZKURT. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class programmeDetailVC: ViewControllerPannable {
    
    @IBOutlet weak var channelLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var popView: UIView!
    @IBOutlet weak var wv: UIWebView!
    @IBOutlet weak var toolBar: UIToolbar!
    
    let loading = UIActivityIndicatorView()
    var detailID = "" //segue
    var toolBarEnabled = [true, true]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLoading(loading: loading, view: self.view) //loading oluşturuyoruz.
        getProgrammeDetail(detailID: detailID) //json işlemleri
        //cok buyük ekranlarda popup autolayoud ile pek iyi gözükmüyordu manuel fixledim..
         if self.view.frame.height >= 1024 { //ipad
            self.popView.frame.size.height = 600
        }

        
        //farklı viewlerden geçiş yapıyorum ve bazı viewlerde bazı toolbarlar işlevsiz oluyor bunları gizlemek adına aşağıdaki kodu kullanıyorum. Seguede toolBarEnabled verisini veriyorum.
        if let item = toolBar.items {
            item[0].isEnabled = toolBarEnabled[0]
            item[1].isEnabled = toolBarEnabled[1]
            setAlarmImage(item: item[1])
        }
        
        
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        dismiss(animated: false, completion: nil) //farklı bir alt menüye geçince popView yani bu sayfa açık kaldıysa bir bug oluyordu bizde farklı bir sayfaya geçiş olursa (bu fonk. çalışıyor) açık bırakılmış popup varsa kapatıyoruz.
    }
    
    
    func setAlarmImage(item: UIBarButtonItem){
        if remindProgramme.contains(where: {$0["ID"] as? String == self.detailID}) { //eger hatırlat demiş ise
            item.image = UIImage(named: "barAlarmFilled")
            item.tintColor = UIColor(red:0.46, green:0.84, blue:1.00, alpha:1.0) //sky
        } else {
            item.image = UIImage(named: "barAlarm")
            item.tintColor = UIColor(red:1.00, green:1.00, blue:1.00, alpha:0.85) //white
        }
    }
    
    func getProgrammeDetail(detailID: String){
        if let index = remindProgramme.lastIndex(where: {$0["ID"] as! String == detailID}){
                self.popView.backgroundColor = UIColor(red:0, green:0.569, blue:0.568, alpha:1) //teal
            let text = remindProgramme[index]["informationHTML"] as! String
                if text == "" {
                    self.wv.loadHTMLString( "<body><style>body {background-color:gray;margin:0px;padding:10px;color:rgba(255, 255, 255, 0.85);font: -apple-system-body; font-size:17;} ul {list-style: none; padding: 10} li {margin-bottom:5px}</style></body>", baseURL: nil)
                } else {
                    self.wv.loadHTMLString( remindProgramme[index]["informationHTML"] as! String, baseURL: nil)
                }
                self.channelLabel.text =  remindProgramme[index]["channel"] as? String
                self.titleLabel.text =  remindProgramme[index]["name"] as? String
                if remindProgramme[index]["time"] as? String != "" {
                    self.timeLabel.text = remindProgramme[index]["time"] as? String
                } else {
                    self.timeLabel.text = timestampToDateTime(timestamp: remindProgramme[index]["datetime"] as! Int)
                }
               self.toolBar.isHidden = false
        } else {
            self.wv.isHidden = true //ilk açılışta gizliyoruz.
            loading.startAnimating()
            Alamofire.request("\(backendUrl)/programmeDetail.asp?id=\(detailID)", method: .get).validate().responseString { response in
                switch response.result {
                case .success(let value):
                    DispatchQueue.main.async {
                        let json = JSON(parseJSON: value)
                        if (json["status"].string == "success") {
                            self.loading.stopAnimating()
                            self.popView.backgroundColor = UIColor(red:0, green:0.569, blue:0.568, alpha:1) //teal
                            self.wv.loadHTMLString(json["informationHTML"].stringValue, baseURL: nil)
                            self.channelLabel.text = json["channel"].stringValue
                            self.titleLabel.text = json["title"].stringValue
                            self.timeLabel.text = json["time"].stringValue
                            
                            UIView.transition(with:self.wv,duration:0.5,options: UIView.AnimationOptions.showHideTransitionViews ,animations:{
                                self.wv.isHidden = false
                                self.toolBar.isHidden = false
                            })
                        } else {
                            let alert = UIAlertController(title: "UYARI", message: "Bir problemden dolayı program detayı görüntülenemedi. Lütfen daha sonra tekrar deneyiniz.", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "Kapat", style: UIAlertAction.Style.cancel, handler: nil))
                            alert.addAction(UIAlertAction(title: "Yeniden Dene", style: UIAlertAction.Style.default, handler: { (UIAlertAction) in
                                self.getProgrammeDetail(detailID: detailID)
                            }))
                            self.present(alert, animated: true, completion: nil)
                        }
                    }
                case .failure(let error):
                    let alert = UIAlertController(title: "Hata", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Kapat", style: UIAlertAction.Style.cancel, handler: nil))
                    alert.addAction(UIAlertAction(title: "Yeniden Dene", style: UIAlertAction.Style.default, handler: { (UIAlertAction) in
                        self.getProgrammeDetail(detailID: detailID)
                    }))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    @IBAction func close(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func btnShare(_ sender: Any) {
        
        //Set the default sharing message.
        let link = NSURL(string: myAppStoreUrl)
        //Set the link to share.
        let message = "\(String(describing: titleLabel.text!)) \(String(describing: timeLabel.text!)) \(String(describing: channelLabel.text!)) kanalında."

        let objectsToShare = [message as Any,link as Any]
        let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        
        activityVC.excludedActivityTypes = [UIActivity.ActivityType.airDrop, UIActivity.ActivityType.addToReadingList]
        self.present(activityVC, animated: true, completion: nil)
   
        
        
    }
    
    @IBAction func btnRemindMe(_ sender: Any) {
        NotificationCenter.default.post(name: NSNotification.Name("remindMePopup"), object: nil)
        if let item = toolBar.items {
            setAlarmImage(item: item[1])
        }
        
    }
    
    @IBAction func btnSearchForWeek(_ sender: Any) {
        let data:[String:String] = ["searchedTitle":titleLabel.text!]
        NotificationCenter.default.post(name: NSNotification.Name("searchForWeek"), object: nil, userInfo: data)
        if titleLabel.text! != " " {//storyboardda boşluk verdim
            dismiss(animated: true, completion: nil)
        }
    }
    
    
}
