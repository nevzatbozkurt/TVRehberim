//
//  channelDetailVC.swift
//  TV Rehberim
//
//  Created by Nevzat BOZKURT on 18.01.2019.
//  Copyright © 2019 Nevzat BOZKURT. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON


class channelDetailVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    @IBOutlet weak var tv: UITableView!
    

    var channelID: Int = 0 //diger viewden gelen kanal id
    var days = [Days]() //Jsondan gelecek
    var filteredDays = [Days]() //aramadan gelecek
    var isSearching = false //arama için
    let loading = UIActivityIndicatorView()
    var currentProgrammeIndex = IndexPath(row: 0, section: 0) //aktif program için index. Kullanım yeri: bu indexe göre aktif program title renkleniyor.
    var currentProgrammeProgressRatio:CGFloat = 0.0 //Kullanım yeri: bu değerin oranına göre aktif program arka planı renkleniyor.
    var currentProgrammeTime: Int = 0 //şimdiki program için zaman kodu. Kullanım yeri: mevcut programın ilerleyişi view ile renkli bir şekilde gösteriliyor.
    var currentChannelTitle: String = ""
    var selectedProgrammeIndex: IndexPath = [] //seguede kullanılacak
    let searchBar = UISearchBar()
    
   
    
    override func viewDidDisappear(_ animated: Bool) {
        //view her kayboldugunda notification trigerları pasif ediyorum sebebi: ileri geri viewlerda dolaşınca bu işlemi yapmazsak bir den fazla tetikleme olacak.
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("searchForWeek"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("remindMePopup"), object: nil)    }
    
    override func viewWillAppear(_ animated: Bool) {
        //view her gorundugunde notification trigerları aktif ediyorum
        NotificationCenter.default.addObserver(self, selector: #selector(searchForWeek(_:)), name: NSNotification.Name("searchForWeek"), object: nil) //programmeDetailVC dan gelen veri ile arama yapmayı takip ediyor..
        NotificationCenter.default.addObserver(self, selector: #selector(remindMePopup), name: NSNotification.Name("remindMePopup"), object: nil) //programmeDetailVC dan gelen veri ile arama yapmayı takip ediyor..

        // [START Google Analytics]       
        guard let tracker = GAI.sharedInstance().defaultTracker else { return }
        tracker.set(kGAIScreenName, value: currentChannelTitle)
        
        guard let builder = GAIDictionaryBuilder.createScreenView() else { return }
        tracker.send(builder.build() as [NSObject : AnyObject])
        // [END Google Analytics]
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.automaticallyAdjustsScrollViewInsets = false //ios9 collectionview boslugu fixledi
        tv.keyboardDismissMode = .onDrag//scroll yapınca klavyeyi gizle
        setupLoading(loading: loading, view: self.view)
        setupSearchBar()
        getChannelDetail(channelID: channelID)
        
     
    }

    
    @objc func searchForWeek(_ notification:Notification) {
        if let searched = notification.userInfo?["searchedTitle"] as? String {
            searchBar.text = searched
            self.searchBar(self.searchBar, textDidChange: searched)
        }
    }
    
    
    @objc func remindMePopup() {
        self.setAlarm(index: selectedProgrammeIndex)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        tv.reloadData()
    }

    func setupSearchBar(){
        
        searchBar.delegate = self
        searchBar.returnKeyType = .done
        searchBar.sizeToFit()
        searchBar.barStyle = .black
        searchBar.placeholder = "Program Ara"
        searchBar.searchBarStyle = .minimal
        navigationItem.titleView = searchBar
    }

    
    
    func findNextProgrammeTime(indexPath: IndexPath) -> Int { //currentIndexPath

        if (self.days[indexPath.section].programme.count-1 > indexPath.row) { //mevcut gün içerisindeki programlar hala bitmediyse bir sonraki programı secebilirim
            if let next = days[indexPath.section].programme[indexPath.row + 1].datetime{
                return next
            }
        } else if (self.days[indexPath.section].programme.count-1 == indexPath.row) && (self.days.count-1 > indexPath.section) { //simdiki günun son programi ise sonraki güne geçip -eger mumkunse kontrol edip- ilk programı alacagiz.
            if days[indexPath.section+1].programme.count >= 0 {
                if let next = days[indexPath.section+1].programme[0].datetime{
                    return next
                }
            }
        }
        return 0
    }
    
    func findProgrammeTime(animated: Bool) { //yayındaki programın IndexPathini buluyor
        for dayIndex in 0..<days.count {
            if let i = days[dayIndex].programme.lastIndex(where: { $0.datetime! <= Int(Date().timeIntervalSince1970) }) {
                currentProgrammeIndex = IndexPath(row: i, section: dayIndex)
                if let now = days[dayIndex].programme[i].datetime{
                    currentProgrammeTime = now
                }
            }
        }
        self.tv.scrollToRow(at: currentProgrammeIndex, at: UITableView.ScrollPosition.top, animated: animated)
    }
    
    
    func getChannelDetail(channelID: Int){
        self.tv.isHidden = true //veri çekiyorken tableviewi gizliyoruz.
        loading.startAnimating()
        Alamofire.request("\(backendUrl)/channelDetail.asp?id=\(channelID)", method: .get).validate().responseString { response in
            switch response.result {
            case .success(let value):
                DispatchQueue.main.async {
                    let json = JSON(parseJSON: value)
                    if (json["status"].string == "success") {
                        self.currentChannelTitle = json["title"].stringValue
                        for item in json["days"].arrayValue {
                            self.days.append(Days(json: item))
                        }
                        UIView.transition(with:self.tv,duration:0.35,options:.transitionCrossDissolve,animations:{
                            self.loading.stopAnimating()
                            self.tv.isHidden = false
                            self.tv.reloadData()
                            self.findProgrammeTime(animated: true)
                            
                            let progressTime = Int(Date().timeIntervalSince1970) - self.currentProgrammeTime
                            let programmeTime  = self.findNextProgrammeTime(indexPath:  self.currentProgrammeIndex) - self.currentProgrammeTime
                            self.currentProgrammeProgressRatio = CGFloat(progressTime)/CGFloat(programmeTime)
                        })
                    } else {
                        let alert = UIAlertController(title: "UYARI", message: "Bir problemden dolayı akış görüntülenemedi. Lütfen daha sonra tekrar deneyiniz.", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Kapat", style: UIAlertAction.Style.cancel, handler: nil))
                        alert.addAction(UIAlertAction(title: "Tekrar Dene", style: UIAlertAction.Style.default, handler: { (UIAlertAction) in
                            self.getChannelDetail(channelID: self.channelID)
                        }))
                        self.present(alert, animated: true, completion: nil)
                    }
                }
            case .failure(let error):
                let alert = UIAlertController(title: "Hata", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Kapat", style: UIAlertAction.Style.cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "Tekrar Dene", style: UIAlertAction.Style.default, handler: { (UIAlertAction) in
                    self.getChannelDetail(channelID: self.channelID)
                }))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if isSearching{
            return filteredDays[section].title! + " (\(self.currentChannelTitle))"
        } else {
            return days[section].title! + " (\(self.currentChannelTitle))"
        }
    }
    
     func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.adjustsFontSizeToFitWidth = true
        header.textLabel?.minimumScaleFactor = 0.5
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if isSearching{
            if filteredDays.count > 0 {
                tableView.backgroundView = nil
                tableView.separatorStyle = .singleLine
            }
            else{
                let noDataLabel: UILabel     = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
                noDataLabel.text          = "Aramanıza uygun bir sonuç bulunamadı."
                noDataLabel.textColor     = UIColor.white
                noDataLabel.textAlignment = .center
                tableView.backgroundView  = noDataLabel
                tableView.separatorStyle  = .none
            }
            return filteredDays.count
        } else {
            return days.count
        }

        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) ->
        Int {
            if isSearching{
                return filteredDays[section].programme.count
            } else {
                return days[section].programme.count
            }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
         let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! channelTVCell
        if isSearching {
            //bana hatırlat - alarm
            if remindProgramme.contains(where: {$0["ID"] as? String == filteredDays[indexPath.section].programme[indexPath.row].detailID}) { //eger hatırlat demiş ise
                cell.alarmButton.setImage(UIImage(named: "alarmFilled"), for: UIControl.State.normal)
                cell.alarmButton.accessibilityLabel = "Alarm Kurulmuş"
                cell.alarmButton.tintColor = UIColor(red:0.46, green:0.84, blue:1.00, alpha:1.0) //sky
            } else {
                cell.alarmButton.setImage(UIImage(named: "alarm"), for: UIControl.State.normal)
                cell.alarmButton.accessibilityLabel = "Alarm Kur"
                cell.alarmButton.tintColor = UIColor(red:1.00, green:1.00, blue:1.00, alpha:0.85) //white
            }
            //Bitti
            
            //alarmi geçmiş programlarda iptal etmek için
            if filteredDays[indexPath.section].programme[indexPath.row].datetime! > Int(Date().timeIntervalSince1970){
                cell.alarmButton.isEnabled = true
            } else {
                cell.alarmButton.isEnabled = false
            }
            //Bitti
            
            cell.programmeTitleLabel.textColor = UIColor(red:1.00, green:1.00, blue:1.00, alpha:0.85) //şimdiki program başlığını gösteren renkte kalmaması için default renke çekiyorum hepsini.
            
            cell.programmeProgressView.isHidden = true //şimdiki programı gösterecek viewi aramada gizliyoruz.
            
            cell.programmeTitleLabel!.text = filteredDays[indexPath.section].programme[indexPath.row].name
            cell.programmeInfoTextView!.text = filteredDays[indexPath.section].programme[indexPath.row].info != "" ? filteredDays[indexPath.section].programme[indexPath.row].info:"Program detayı mevcut değil"
            cell.programmeTimeLabel!.text = filteredDays[indexPath.section].programme[indexPath.row].time
            cell.programmeInfoTextView.sizeToFit()
        } else {
            //bana hatırlat - alarm
            if remindProgramme.contains(where: {$0["ID"] as? String == days[indexPath.section].programme[indexPath.row].detailID}) { //eger hatırlat demiş ise
                cell.alarmButton.setImage(UIImage(named: "alarmFilled"), for: UIControl.State.normal)
                cell.alarmButton.accessibilityLabel = "Alarm Kurulmuş"
                cell.alarmButton.tintColor = UIColor(red:0.46, green:0.84, blue:1.00, alpha:1.0) //sky
            } else {
                cell.alarmButton.setImage(UIImage(named: "alarm"), for: UIControl.State.normal)
                cell.alarmButton.accessibilityLabel = "Alarm Kur"
                cell.alarmButton.tintColor = UIColor(red:1.00, green:1.00, blue:1.00, alpha:0.85) //white
            }
            //Bitti
            
            //zamanı geçmiş programlarda alarmı pasif yapmak için
            if days[indexPath.section].programme[indexPath.row].datetime! > Int(Date().timeIntervalSince1970){
                cell.alarmButton.isEnabled = true
            } else {
                cell.alarmButton.isEnabled = false
            }
            //Bitti
            
            //şimdiki programın başlığını renklendirmek için
            if self.currentProgrammeIndex == indexPath {
                cell.programmeTitleLabel.textColor = UIColor(red:0.46, green:0.84, blue:1.00, alpha:1.0) //sky
                
                

                if currentProgrammeProgressRatio >= 0.01 && currentProgrammeProgressRatio <= 1 {
                    cell.programmeProgressView.isHidden = false //simdiki programin ilerlemesini gösteren viewi aktif ediyoruz.
                    cell.programmeProgressView.frame.size.width = cell.frame.width * currentProgrammeProgressRatio
                }
                
                
            } else {
                cell.programmeTitleLabel.textColor = UIColor(red:1.00, green:1.00, blue:1.00, alpha:0.85) //white
                cell.programmeProgressView.isHidden = true
            }
            cell.programmeTitleLabel!.text = days[indexPath.section].programme[indexPath.row].name
            cell.programmeInfoTextView!.text = days[indexPath.section].programme[indexPath.row].info != "" ? days[indexPath.section].programme[indexPath.row].info:"Program detayı mevcut değil"
            cell.programmeTimeLabel!.text = days[indexPath.section].programme[indexPath.row].time
            cell.programmeInfoTextView.sizeToFit()
        }
        
        //set alarm start
        cell.index = indexPath
        cell.delegate = self
        //set alarm end
        return cell
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.endEditing(true)
        //aramayi bitirip tv yeniliyoruz.
        endSearching()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
        (searchBar.value(forKey: "cancelButton") as! UIButton).setTitle("İptal", for: .normal)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText != "" { //arama metni boş değilse
            self.filteredDays.removeAll(keepingCapacity: true)//filtrelenmiş kanal varsa önce temizliyoruz. yeniden filtereneceği için.
            self.isSearching = true //aramaya başladığını belirtiyorum tableview de ona göre değişken seçimi yapıyor..
            var program = [Programme]() //her gündeki programı tutacagim degiskenim
            for day in days { //gun gun donuyoruz..
                //program başlıkları arasında aramamıza uygun olanları yukarıda oluşturdugumuz programa ekliyorum neden arkasına ekledim dersen 1 den fazla gun olacagi için tüm günleri arayarak ekliyoruz.
                
                program += day.programme.filter { prg in
                    return (prg.name!.localizedCaseInsensitiveContains("\(searchText.localizedUppercase)"))
                }
                if program.count > 0 {self.filteredDays.append(Days.init(title: day.title!, programme: program))} //eger mevcut gün içerisinde aramaya uygun bir program var ise o gunu Days classına atıyorum.
                program.removeAll(keepingCapacity: true) //yeni güne geçmeden mevcut gundeki programları tutan değişkenimi temizliyorum.
            }
            //her şey hazır... tableview'imi yeniliyorum..
            
            UIView.transition(with:tv,duration:0.15,options:.transitionCrossDissolve,animations:{self.tv.reloadData()})
            self.tv.layoutIfNeeded()//asagidaki kodu fixliyor normalde asagidaki kodla scroll en basa gelmesi gerekiyorken gelmiyor ama bu kod sayesinde aşağıdaki kod işe yarıyor.
            self.tv.setContentOffset( CGPoint(x: 0.0, y: 0.0), animated: false)
            //self.tv.endUpdates()
            
            
        } else { //eğer arama metini sıfırlanırsa aramayı sonlandırıyoruz.
            endSearching()
        }
    }
    
    func endSearching(){
        self.isSearching = false //aramanın bittiğini belirtiyorum tableview de ona göre değişken seçimi yapıyor..
        UIView.transition(with:tv,duration:0.15,options:.transitionCrossDissolve,animations:{self.tv.reloadData()})
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedProgrammeIndex = indexPath
        performSegue(withIdentifier: "programmeDetailSegue2", sender: self)
        
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "programmeDetailSegue2" {
            let destinationVC = segue.destination as! programmeDetailVC
            var alarmVisibility = false
            if isSearching {
                destinationVC.detailID = filteredDays[selectedProgrammeIndex.section].programme[selectedProgrammeIndex.row].detailID!
                alarmVisibility = filteredDays[selectedProgrammeIndex.section].programme[selectedProgrammeIndex.row].datetime! > Int(Date().timeIntervalSince1970)
                
            } else {
                destinationVC.detailID = days[selectedProgrammeIndex.section].programme[selectedProgrammeIndex.row].detailID!
                alarmVisibility = days[selectedProgrammeIndex.section].programme[selectedProgrammeIndex.row].datetime! > Int(Date().timeIntervalSince1970)
            }
            destinationVC.toolBarEnabled = [true, alarmVisibility]
        }
    }
}


//set alarm start
extension channelDetailVC: setAlarmProtocol {
    func setAlarm(index: IndexPath) {
        
        
        if let settings = UIApplication.shared.currentUserNotificationSettings {
            if settings.types.contains([.alert]) || settings.types.contains([.badge]) || settings.types.contains([.sound]) { //eger herhangi bir bildirim izni verilmiş ise bildirimi ayarlıyoruz.
                
                
                
                
                let cell = tv.cellForRow(at: index) as! channelTVCell
                var selectedPrg = [Programme]()
                if isSearching{
                    selectedPrg = [filteredDays[index.section].programme[index.row]]
                } else {
                    selectedPrg = [days[index.section].programme[index.row]]
                }
                
                //bana hatırlat - alarm
                if let indexx = remindProgramme.firstIndex(where: {$0["ID"] as? String == selectedPrg[0].detailID}) { //eger hatırlat demiş ise siliyoruz.
                    remindProgramme.remove(at: indexx) //hatirlatmaktan vaz geçti
                    UIView.animate(withDuration: 0.25, animations: {
                        cell.alarmButton.alpha = 0
                    }, completion: { (finished) in
                        cell.alarmButton.setImage(UIImage(named: "alarm"), for: UIControl.State.normal)
                        cell.alarmButton.accessibilityLabel = "Alarm Kur"
                        cell.alarmButton.tintColor = UIColor(red:1.00, green:1.00, blue:1.00, alpha:0.85) //white
                        cancelLocalNotification(uniqueId: selectedPrg[0].detailID!)
                        UIView.animate(withDuration: 0.5, animations: {
                            cell.alarmButton.alpha = 1
                        }, completion: {(finished) in
                            saveRemindProgramme()
                            changeBadge(itemIndex: 1, newValue: remindProgramme.count)
                        })
                    })
                    
                } else { //yeni hatırlatmak istemiş ise hatırlatmak için ekliyoruz.
                    //program çıkışında kayıt etmek ayrıca uygulama içindeki gösteriml ve kontrol için seçileni diziye alıyorum...
                    remindProgramme.append(["channel":self.currentChannelTitle,"ID":selectedPrg[0].detailID!,"name":selectedPrg[0].name!,"datetime":selectedPrg[0].datetime!,"time":"","informationHTML":""])
                    
                    programmeInformationCache(detailID: selectedPrg[0].detailID!)
                    
                    UIView.animate(withDuration: 0.25, animations: {
                        cell.alarmButton.alpha = 0
                    }, completion: { (finished) in
                        cell.alarmButton.setImage(UIImage(named: "alarmFilled"), for: UIControl.State.normal)
                        cell.alarmButton.accessibilityLabel = "Alarm Kurulmuş"
                        cell.alarmButton.tintColor = UIColor(red:0.46, green:0.84, blue:1.00, alpha:1.0) //sky
                        setNotification(body: "\(selectedPrg[0].name!) birazdan \(self.currentChannelTitle) kanalında başlıyor...", alertAction: "Kapat", userInfo: ["ID": selectedPrg[0].detailID!], date: Date(timeIntervalSinceNow: TimeInterval(selectedPrg[0].datetime! - Int(Date().timeIntervalSince1970)-delayInterval)), soundName: UILocalNotificationDefaultSoundName)
                        UIView.animate(withDuration: 0.5, animations: {
                            cell.alarmButton.alpha = 1
                        }, completion: {(finished) in
                            saveRemindProgramme()
                            changeBadge(itemIndex: 1, newValue: remindProgramme.count)
                        })
                    })
                }
                
                
                
                
                
                
            } else  {
                let settingsButton = NSLocalizedString("Ayarlar", comment: "")
                let cancelButton = NSLocalizedString("İptal", comment: "")
                let message = NSLocalizedString("Programı hatırlatabilmem için bildirimleri açman gerekiyor.", comment: "")
                let goToSettingsAlert = UIAlertController(title: "", message: message, preferredStyle: UIAlertController.Style.alert)
                
                goToSettingsAlert.addAction(UIAlertAction(title: settingsButton, style: .destructive, handler: { (action: UIAlertAction) in
                    DispatchQueue.main.async {
                        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                            return
                        }
                        
                        if UIApplication.shared.canOpenURL(settingsUrl) {
                            if #available(iOS 10.0, *) {
                                UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                                })
                            } else {
                                UIApplication.shared.openURL(settingsUrl as URL)
                            }
                        }
                    }
                }))
                
                goToSettingsAlert.addAction(UIAlertAction(title: cancelButton, style: .cancel, handler: nil))
                UIApplication.shared.keyWindow?.rootViewController?.present(goToSettingsAlert, animated: true, completion: nil)
                
            } //bildiirm izni if end
        } //bildirim ayarı iflet end
        

    }
    
    func programmeInformationCache(detailID: String) {
        //amacı: internet olmadığı halde bile bildirimden programa tıklayınca programın detayını göstermek için cacheliyoruz... Eğer cache başarısız olursa problem yok sadece detayı ve detaylı zamanı gösteremiyoruz, zaman için çözüm var ama detay için yapcak bir şey yok maalesef.
        Alamofire.request("\(backendUrl)/programmeDetail.asp?id=\(detailID)", method: .get).validate().responseString { response in
            switch response.result {
                case .success(let value):
                    let json = JSON(parseJSON: value)
                    if (json["status"].string == "success") {
                        if let index = remindProgramme.lastIndex(where: {$0["ID"] as! String == detailID}){
                            remindProgramme[index]["informationHTML"] = json["informationHTML"].stringValue
                            remindProgramme[index]["time"] = json["time"].stringValue
                        }
                    }
            case .failure(_):
                 return
            }
            
        }
        
    }
    
    
}
//set alarm end
