//
//  Func.swift
//  TV Rehberim
//
//  Created by Nevzat BOZKURT on 19.01.2019.
//  Copyright © 2019 Nevzat BOZKURT. All rights reserved.
//

import UIKit
import MessageUI

let delayInterval = 60

func setupLoading(loading: UIActivityIndicatorView, view: UIView){
    loading.frame = CGRect(x: view.frame.midX-25, y: view.frame.midY-25, width: 50, height: 50)
    loading.hidesWhenStopped = true
    //loading.stopAnimating()
    loading.style = .whiteLarge
    view.addSubview(loading)
}

func setNotification(body: String,alertAction: String, userInfo: [String:String], date: Date, soundName: String){
    let notification = UILocalNotification()
    notification.alertBody = body
    notification.alertAction = alertAction
    notification.userInfo = userInfo
    //notification.fireDate = Date(timeIntervalSinceNow: 5)
    notification.fireDate =  date
    notification.soundName = soundName
    UIApplication.shared.scheduleLocalNotification(notification)
}
func cancelLocalNotification(uniqueId: String){
    // 2. Create an array of notifications, ensuring to use `if let` so it fails gracefully
    if let notifyArray = UIApplication.shared.scheduledLocalNotifications {
        // 3. For each notification in the array ...
        for notif in notifyArray as [UILocalNotification] {
            // ... try to cast the notification to the dictionary object
            if let info = notif.userInfo as? [String: String] {
                // 4. If the dictionary object ID is equal to the string you passed in ...
                if info["ID"] == uniqueId {
                    // ... cancel the current notification
                    UIApplication.shared.cancelLocalNotification(notif)
                }
            }
        }
    }
}

func saveRemindProgramme(){
    //ilk önce hatırlatılacak programları yayın tarihine göre sıralıyoruz.
    remindProgramme.sort { ($0["datetime"] as! Int) < ($1["datetime"] as! Int) }
    //daha sonra kayıt ediyoruz.
    UserDefaults.standard.set(remindProgramme, forKey: "remindProgramme")
    UserDefaults.standard.synchronize()
}

func getRemindProgramme(){
    //ilk önce veriyi alıyorum
    if let arr = UserDefaults.standard.object(forKey: "remindProgramme")  {
        remindProgramme = arr as! [[String : Any]]
    }
    //daha sonra ise geçmiş tarihli bildirimler varsa onları temizliyoruz
    remindProgramme.removeAll { (a) -> Bool in
        //(a["datetime"] as! Int) < Int(Date().timeIntervalSince1970) && (a["ID"] as!String) != notifProgrammeID //tarihi bugunun tarihinden  küçük ve bildirimden gelen idli olmayanları temizliyoruz..
        (a["datetime"] as! Int) < Int(Calendar.current.date(byAdding: .hour, value: -12, to: Date())!.timeIntervalSince1970) && (a["ID"] as!String) != notifProgrammeID //tarihi bugunun tarihi-12 saat öncesinden küçük ve bildirimden gelen idli olmayanları temizliyoruz..
        
    }

    
}



func changeBadge(itemIndex: Int, newValue: Int){
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let tabBarController = appDelegate.window!.rootViewController as! UITabBarController 
    if let tabItems = tabBarController.tabBar.items  {
        let tabItem = tabItems[itemIndex]
        if newValue == 0 {
            tabItem.badgeValue = nil
        } else {
            tabItem.badgeValue = "\(newValue)"
        }
    }


}


func timestampToDateTime(timestamp: Int) -> String {
    let date = Date(timeIntervalSince1970:  TimeInterval(timestamp))
    let formatter = DateFormatter()
    formatter.dateFormat = "dd.MM.yyyy HH:mm"
    formatter.timeZone = TimeZone(abbreviation: "GTM+3")
    return formatter.string(from: date)
}


