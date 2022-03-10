//
//  remindedProgrammeVC.swift
//  
//
//  Created by Nevzat BOZKURT on 30.01.2019.
//

import UIKit

class remindedProgrammeVC: UIViewController, UITableViewDelegate,UITableViewDataSource {
 
    @IBOutlet weak var clearBtn: UIBarButtonItem!
    @IBOutlet weak var tv: UITableView!
    var selectedProgrammeID = "" //seguede kullanılacak
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.automaticallyAdjustsScrollViewInsets = false //ios9 collectionview boslugu fixledi
        clearBtn.accessibilityLabel = "Tüm Hatırlatıcıları Temizle"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        tv.reloadData()
        //bildirimden geçiş yapıldıysa
        if notifProgrammeID != "" { //appdelegateden tanımlanan program id var ise bildirime tiklayarak gelmiştir.
            self.selectedProgrammeID = notifProgrammeID
            notifProgrammeID = "" //bildirimden gelen veriyi temizliyoruz bu sayfaya bildirim disinde her gelindiğinde (bildirimden geliş oturumunda gezinirken yani) yanlis bilgi göstermemesi adına
            performSegue(withIdentifier: "programmeDetailSegue", sender: self)
        }
        
        //bildirim bitti
    }

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if remindProgramme.count>0{
            tableView.backgroundView = nil
        }
        else{
            let noDataLabel: UILabel     = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
            noDataLabel.numberOfLines = 0
            noDataLabel.text          = "Hatırlatılacak bir yayın yok.\nHerhangi bir yayına bildirim almak için \nsaat ikonuna tıklamanız yeterli."
            noDataLabel.textColor     = UIColor.white
            noDataLabel.textAlignment = .center
            tableView.backgroundView  = noDataLabel
        }
        return remindProgramme.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
       
        if indexPath.row % 2 == 0 {
            cell.backgroundColor = UIColor(red:0.44, green:0.44, blue:0.47, alpha:1.0)
        } else {
             cell.backgroundColor = UIColor(red:0.44, green:0.44, blue:0.47, alpha:0.75)
        }
        
        cell.tintColor = UIColor(red:0.46, green:0.84, blue:1.00, alpha:1.0)
        //bildirim gönderilenleri check olarak gösteriyoruz.
        if remindProgramme[indexPath.row]["datetime"] as! Int > Int(Date().timeIntervalSince1970){
            cell.accessoryType = .none
        } else {
            cell.accessoryType = .checkmark
        }
        //Bitti
        
        cell.textLabel?.text = remindProgramme[indexPath.row]["name"] as? String
        cell.detailTextLabel?.text = "\(timestampToDateTime(timestamp: remindProgramme[indexPath.row]["datetime"] as! Int)) (\(String(describing: remindProgramme[indexPath.row]["channel"] as! String)))"
        return cell
        
    }
 
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let id = remindProgramme[indexPath.row]["ID"] {
            self.selectedProgrammeID = id as! String
            performSegue(withIdentifier: "programmeDetailSegue", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "programmeDetailSegue" {
            let destinationVC = segue.destination as! programmeDetailVC
            destinationVC.toolBarEnabled = [false, false]//eğer hatırlatıcı sayfasından açıyorsak toolbardaki bazı itemleri göstermeye gerek olmayacağı için gizliyoruz. aslında arama işlemi çalışmayacağı için kapatıyorum.
            destinationVC.detailID = self.selectedProgrammeID
        }
    }
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Sil"
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            let delID = remindProgramme[indexPath.row]["ID"] as! String
            if let indexx = remindProgramme.firstIndex(where: {$0["ID"] as? String == delID}){
                remindProgramme.remove(at: indexx)
                cancelLocalNotification(uniqueId: delID)
                saveRemindProgramme()
                changeBadge(itemIndex: 1, newValue: remindProgramme.count)
                tv.beginUpdates()
                tv.deleteRows(at: [indexPath], with: .left)
                tv.endUpdates()
            }
            
        }
    }
    
    
    @IBAction func clearNotifications(_ sender: Any) {
        let areYouSureAlert = UIAlertController(title: "Bütün Bildirimleri Temizle", message: "İşleme devam etmek istiyor musunuz?", preferredStyle: UIAlertController.Style.alert)
        let yesAction = UIAlertAction(title: "Evet", style: UIAlertAction.Style.default) { (UIAlertAction) in
            UIApplication.shared.cancelAllLocalNotifications() //tüm bildirimleri sil
            remindProgramme.removeAll(keepingCapacity: true) //tum bildirimleri degiskenden sil
            saveRemindProgramme() //degisikleri kaydet.
            changeBadge(itemIndex: 1, newValue: remindProgramme.count) //badge degistir.
            self.tv.reloadData() //tabloyu yenile.
        }
        areYouSureAlert.addAction(yesAction)
        areYouSureAlert.addAction(UIAlertAction(title: "Hayır", style: UIAlertAction.Style.cancel, handler: nil))
        present(areYouSureAlert, animated: true, completion: nil)
    }
    

}
