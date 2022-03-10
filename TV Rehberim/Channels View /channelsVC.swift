//
//  channelsView.swift
//  TV Rehberim
//
//  Created by Nevzat BOZKURT on 6.01.2019.
//  Copyright © 2019 Nevzat BOZKURT. All rights reserved.
//


import UIKit
import Alamofire
import SwiftyJSON
import SDWebImage
import GoogleMobileAds

var channels = [Channels]()
var favoriteChannels = [Channels]() //favori kanalları tutacagım değişken.
var remindProgramme = [[String:Any]]() //hatırlatılacak olan programları tutuyor.


class channelsVC: UIViewController, UICollectionViewDelegateFlowLayout,UICollectionViewDelegate, UICollectionViewDataSource,UIGestureRecognizerDelegate,UISearchBarDelegate {
  
    @IBOutlet weak var channelsCV: UICollectionView!
    @IBOutlet weak var categoryCV: UICollectionView!
    @IBOutlet weak var favoriteBtn: UIBarButtonItem!
    
    var interstitial: GADInterstitial!
    var filterChannels = [Channels]() //kategoriye göre ayirmada ise yarayacak
    var defaultCat = 0 // varsayılan kategorimiz
    var selectedCat = "tum" //secilen kategorimiz
    var selectedChannelID = 0 //tiklanan kanal idsi segue de kullanilacak
    var cats = [("tum","Tüm Kanallar"), ("favori","Favorilerim"), ("ulusal","Ulusal"),("haber","Haber"),("spor","Spor"),("belgesel","Belgesel"),("dizi","Dizi"),("film","Film"),("muzik","Müzik"),("cocuk","Çocuk"),("yasam","Yaşam"),("uluslararasi","Uluslararası"),("radyo","Radyo")]
    var favoriteMode: Bool = false
    let textPadding:CGFloat = 40.0 //kategori seçimini gösterecek bottom border için metine göre boyut ayarlıyor fakat biraz daha büyük yapmak gerekiyordu ne kadar büyük olacağını burada tanımladım.
    let loading = UIActivityIndicatorView()
    let searchBar = UISearchBar()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.automaticallyAdjustsScrollViewInsets = false //ios9 collectionview boslugu fixledi
        channelsCV.keyboardDismissMode = .onDrag //scroll yapınca klavyeyi gizle
        setupLoading(loading: loading, view: self.view)
        if (channels.count==0) {//eger ilk defa veri alınacak ise değişkendeki sayı 0 olacağı için kanalları alıyorum. Bu kontrolü farklı viewlerdan geçiş yaptığımızda tekrar tekrar kanal listesini almamıza gerek olmadığı için yaptım zaten kanallarımız global değişkenimizde saklı kalacak.
            getChannels()
        }
        
        // create the search bar programatically since you won't be
        searchBar.sizeToFit()
        searchBar.placeholder = "Kanal Ara"
        searchBar.delegate = self
        searchBar.returnKeyType = .done
        searchBar.searchBarStyle = UISearchBar.Style.minimal
        searchBar.barStyle = .black
        navigationItem.titleView = searchBar
        //search bar end
        
        
        let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(favoriteModeOn))
        lpgr.minimumPressDuration = 0.75
        lpgr.delaysTouchesBegan = true
        lpgr.delegate = self
        self.channelsCV.addGestureRecognizer(lpgr)
        
        tabBarController?.tabBar.tintColor = UIColor(red:0.46, green:0.84, blue:1.00, alpha:1.0) //sky
        changeBadge(itemIndex: 1, newValue: remindProgramme.count)
       
       //google admob
        interstitial = GADInterstitial(adUnitID: "ca-app-pub-1121633397436094/9631542970")
        let request = GADRequest()
        interstitial.load(request)
        //google admob end
        
        favoriteBtn.accessibilityLabel = "Favori Kanal Düzenlemeyi Aç"
    }

    
    override func viewDidLayoutSubviews() {
        //secimi göstermek için bir cizgi şeklinde view oluşturup secime ekliyoruz ve default kategorimizi seçilmiş olarak ayarlıyoruz.
        if self.categoryCV.viewWithTag(1) == nil  {  //daha önce bir view eklememişsek. (asagida olusturudumuzu yani. birden fazla olsun istemeyiz.)
            let border = UIView()
            border.tag = 1
            border.backgroundColor = UIColor(red: 255/255, green: 45/255, blue: 85/255, alpha: 0.8)
            border.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
            border.frame = CGRect(x: 0, y: self.categoryCV.frame.size.height-5, width: self.cats[self.defaultCat].1.size().width + textPadding, height: 4)
            border.layer.cornerRadius = 0
            border.layer.opacity = 0.75
            self.categoryCV.addSubview(border)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        // [START Google Analytics]
        let name = "Anasayfa"
        
        guard let tracker = GAI.sharedInstance().defaultTracker else { return }
        tracker.set(kGAIScreenName, value: name)
        
        guard let builder = GAIDictionaryBuilder.createScreenView() else { return }
        tracker.send(builder.build() as [NSObject : AnyObject])
        // [END Google Analytics]
    }
    
    @objc func favoriteModeOn(sender:UILongPressGestureRecognizer){ //longPressGesture var
        if sender.state == .began {
            favoriteModeChange(status: !favoriteMode)
        }

    }
      
    func getChannels(){
        self.channelsCV.isHidden = true //veri çekiyorken collectionview gizliyoruz.
        loading.startAnimating()
        Alamofire.request("\(backendUrl)/channels.json", method: .get).validate().responseString { response in
            switch response.result {
            case .success(let
                value):
                DispatchQueue.main.async {
                    let json = JSON(parseJSON: value)
                    if (json["status"].string == "success") {
                        for item in json["channels"].arrayValue {
                            channels.append(Channels(json: item))
                            self.filterChannels.append(Channels(json: item))
                        }
                        UIView.transition(with:self.channelsCV,duration:0.35,options:.transitionCrossDissolve,animations:{
                            self.loading.stopAnimating()
                            self.channelsCV.isHidden = false
                            self.channelsCV.reloadData()
                        })
                        self.getFavories()//kanalları çektikten sonra favorilerini aliyorum.
                    } else {
                        let alert = UIAlertController(title: "UYARI", message: "Kanalları yüklerken bir hata meydana geldi.", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Kapat", style: UIAlertAction.Style.cancel, handler: nil))
                        alert.addAction(UIAlertAction(title: "Tekrar Dene", style: UIAlertAction.Style.default, handler: { (UIAlertAction) in
                            self.getChannels()
                        }))
                        self.present(alert, animated: true, completion: nil)
                        
                    }
                }
            case .failure(let error):
                let alert = UIAlertController(title: "UYARI", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Kapat", style: UIAlertAction.Style.cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "Tekrar Dene", style: UIAlertAction.Style.default, handler: { (UIAlertAction) in
                    self.getChannels()
                }))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }

    func getFavories(){
        if let fc : [Int] = UserDefaults.standard.object(forKey: "favoriteChannelsIDs") as! [Int]? {
            for id in fc{
                favoriteChannels.append(channels.filter({ $0.id == id})[0])
            }
        }
        //eğer favori kanalı varsa favorileri açıyorum ilk açtığında favorileri gözüküyor
        if favoriteChannels.count > 0 {
            changeCat(catid: "favori", indexPath: IndexPath(row: 1, section: 0))
        }
    }
    
    func saveFavorite(){
        var intArr: [Int] = []
        for id in favoriteChannels {
            intArr.append(id.id!)
        }
        //favorimiz varsa kayit ediyoruz. kalmadıysa olani temizliyoruz.
        if intArr.count > 0 {
            UserDefaults.standard.set(intArr, forKey: "favoriteChannelsIDs")
        } else {
            UserDefaults.standard.removeObject(forKey: "favoriteChannelsIDs")
        }
    }
    
    
    
  
    func changeCat(catid: String, indexPath: IndexPath?){
        self.selectedCat = catid
        
        //aramadayken kategori değişirse armayı sonlandırıyorum
        self.searchBar.endEditing(true)
        self.searchBar.text = ""
        //arama sonlandırma bitti.
        
        if let indexPath = indexPath { //eğer seçimi değiştirmek istemişsek indexpath degeri gelecek. nil geliyorsa seçim değişmiyor demektir.
            //seçimi değiştirme işlemleri başladı
            let cell = categoryCV.cellForItem(at: indexPath) as? categoryCVCell
            let border = categoryCV.viewWithTag(1)
            if let x = cell?.frame.minX {
                UIView.animate(withDuration: 0.4, animations: {
                    border?.frame = CGRect(x: x, y: self.categoryCV.frame.size.height-5, width: self.cats[indexPath.row].1.size().width + self.textPadding, height: 4)
                })
            } else { //eğer tıklanan cellin x pozisyonunu alamaz isem aktiflik göstergesini gizliyorum. bir problem olursa bug olarak kalmasın diye.
                border?.isHidden = true
            }
            //scrollu seçime göre oynatıyor.
            categoryCV.selectItem(at: indexPath, animated: true, scrollPosition: UICollectionView.ScrollPosition.centeredHorizontally)
            //seçimi değiştirme işlemleri bitti
        }

        
        
        
        if catid == "tum" {
            self.filterChannels = channels
        } else if catid == "favori" {
            self.filterChannels = favoriteChannels
        } else {
            self.filterChannels = channels.filter({ $0.category == selectedCat })
        }
        UIView.transition(with:channelsCV,duration:0.35,options:.transitionCrossDissolve,animations:{self.channelsCV.reloadData()})
        self.channelsCV.setContentOffset(CGPoint(x: 0.0, y: 0.0), animated: false)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == channelsCV {
            return filterChannels.count
        } else {
            return cats.count
        }
        
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == channelsCV {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! channelsCVCell
            var isMyFavorite: Bool //voiceover fix için
            cell.checkImage.isHidden = !favoriteMode // favori ekleme işleminde göstereceğimiz imageviewimiz. favori modda değişsek gizli favorideyse açık olacak.
            if (favoriteChannels.filter({ $0.id ==  filterChannels[indexPath.row].id}).count==0){ //eger listelecek kanal favoride degilse unchecked image veriyoruz.
                cell.checkImage.image = UIImage(named: "uncheck")
                isMyFavorite = false
            } else { //eger favorideyse favoride oldugunu belirtiyoruz.
                cell.checkImage.image = UIImage(named :"check")
                isMyFavorite = true
            }
            
            //voiceover fix
            cell.channelImage.isAccessibilityElement = true
            if (favoriteMode) {//favori modunda ise favorileri arasında olup olmadığını söylüyoruz..
                cell.channelImage.accessibilityLabel =  "\(filterChannels[indexPath.row].title!) \(isMyFavorite ? "Favorim":"Favorim Değil")"
                cell.channelImage.accessibilityHint = "Mevcut durumu değiştirmek için 2 kere dokunun"
            } else {
                cell.channelImage.accessibilityLabel = filterChannels[indexPath.row].title
                cell.channelImage.accessibilityHint = "Yayın akışı için 2 kere dokunun"
            }
            //voiceover fix
            cell.channelImage.image = nil
            cell.loading.startAnimating()
            //cell.restorationIdentifier = filterChannels[indexPath.row].category //categorisini değiştirmede kullanacağız
            if let imgID = filterChannels[indexPath.row].id {
                cell.channelImage?.sd_setImage(with: URL(string: "\(backendUrl)/image/\(imgID).png"), placeholderImage: nil, completed: { (image, error, sdImageCacheType, url) in
                    if error == nil {
                        cell.loading.stopAnimating()
                    }
                })
            }
            return cell
        }
        else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "catCell", for: indexPath) as! categoryCVCell
            cell.categoryLabel.text = cats[indexPath.row].1
            return cell
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == channelsCV {
            if favoriteMode { //favori modunda isek seçilen celldeki kanal bigilerini favori değişkenimize kayit edeceğiz.

                //secilen celli buluyoruz
                let cell = collectionView.cellForItem(at: indexPath) as! channelsCVCell
                //secimin oldugu kanal bilgilerini aliyoruz.
                let selectedChannel = filterChannels[indexPath.row]
                
                //favoriler arasında mı diye bakıyoruz.
                if (favoriteChannels.filter({ $0.id == selectedChannel.id }).count==0){ //favoriler arasında değilse
                    //favoriye ekliyoruz ve checked yapiyoruz.
                    favoriteChannels.append(selectedChannel)
                    cell.checkImage.image = UIImage(named: "check")
                    cell.channelImage.accessibilityLabel =  "\(filterChannels[indexPath.row].title!) Favorim"
                } else {//favoriler arasındaysa
                    //favorilerden siliyoruz ve uncheck yapiyoruz.
                    let index = favoriteChannels.firstIndex(where: { $0.title==selectedChannel.title}) //favoriler arasından secilen kanalin indexini buluyoruz.
                    favoriteChannels.remove(at: index!)
                    cell.checkImage.image = UIImage(named: "uncheck")
                      cell.channelImage.accessibilityLabel =  "\(filterChannels[indexPath.row].title!) Favorim Değil"
                }
                
            } else { //favoride degilsek segue yapiyoruz.
                self.view.window?.endEditing(false) //geçiş yaparken klavye açıksa kapatalım.
                if let id = filterChannels[indexPath.row].id {
                    self.selectedChannelID = id
                }
                
                //google admob | önce reklam hazirsa reklami göster..
                if interstitial.isReady {
                    interstitial.present(fromRootViewController: self)
                }
                //google admob end
                
                performSegue(withIdentifier: "channelDetailSegue", sender: self)
            }
            
        } else {
            changeCat(catid: self.cats[indexPath.row].0, indexPath: indexPath)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == channelsCV {
            let margin:CGFloat = 5
            let cell:CGFloat = CGFloat(Int(collectionView.bounds.width / 100))
            let wAndH = (collectionView.frame.width - (margin*(cell+1)) ) / cell
            return CGSize(width: wAndH, height: wAndH)
        } else {
            return CGSize(width: cats[indexPath.row].1.size().width + textPadding, height: collectionView.frame.height)
        }
    }
    
    
   
    
    @IBAction func btnFavoriteMode(_ sender: UIBarButtonItem) {
        if favoriteMode { //favori secim moduna girdik ise kapatıcaz.
            favoriteBtn.accessibilityLabel = "Favori Kanal Düzenlemeyi Aç"
            favoriteModeChange(status: false)
            
        } else { //favoriye ekleme işleminde değilsek
            favoriteBtn.accessibilityLabel = "Favori Kanal Düzenlemeyi Kapat"
            favoriteModeChange(status: true)
        }
    }

    func favoriteModeChange(status:Bool){ //favori mod değiştirme
        self.favoriteMode = status
        if let indexPaths = channelsCV?.indexPathsForVisibleItems {
            for indexPath in indexPaths {
                if let cell = channelsCV?.cellForItem(at: indexPath) as? channelsCVCell {
                    UIView.transition(with:channelsCV,duration:0.25,options:.transitionFlipFromRight,animations:{cell.checkImage.isHidden = !status})
                }
            }
            if status { //favori moduna geciyorsak
                self.favoriteBtn.image = UIImage(named:"heartOutline")
            } else { //normal gorunume geciyorsak
                self.favoriteBtn.image = UIImage(named:"heart")
                if selectedCat == "favori" {
                    self.filterChannels = favoriteChannels
                }
                saveFavorite()//çıkarken kaydediyoruz.
            }
            self.channelsCV.reloadData() //her mod değiştiğinde sayfayı yeniliyoruz hem değişiklik varsa onları güncelliyor hem voiceover label textleri yenilenmiş oluyor..
        }
    }
    

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.endEditing(true)
        //son olarak seçili kategorisi neyse onu tekrar açıyoruz.
        changeCat(catid: self.selectedCat, indexPath: nil)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
    }
    
   
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
        (searchBar.value(forKey: "cancelButton") as! UIButton).setTitle("İptal", for: .normal)
        if let border = categoryCV.viewWithTag(1) { //aramaya başlayınca seçili kategoriyi gösteren viewi gizliyorum
            border.isHidden = true
        }
    }

    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
        if let border = categoryCV.viewWithTag(1) { //aramayı bitirince seçili kategoriyi gösteren viewi gösteriyorum
            border.isHidden = false
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText != "" { //arama metni boş deiğilse
            //kanallar isinleri arasında gecenleri filtreleyip gösteriyoruz.
            self.filterChannels = channels.filter { channel in
                return (channel.title!.localizedCaseInsensitiveContains("\(searchText)"))
            }
                UIView.transition(with:channelsCV,duration:0.15,options:.transitionCrossDissolve,animations:{self.channelsCV.reloadData()})
        } else { //boş ise sildiyse vs vs mevcut kategoriyi yeniden gösteriyoruz. o yeniden filtreliyori içinde zaten.
            changeCat(catid: self.selectedCat, indexPath: nil)
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "channelDetailSegue" {
            let destinationVC = segue.destination as! channelDetailVC
            destinationVC.channelID = self.selectedChannelID
        }
    }
    


    
}




