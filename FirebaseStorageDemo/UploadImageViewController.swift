//
//  UploadImageViewController.swift
//  FirebaseStorageDemo
//
//  Created by Frank.Chen on 2017/5/7.
//  Copyright © 2017年 Frank.Chen. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseStorage

class UploadImageViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    @IBOutlet weak var userImage: UIImageView!
    var dataTask: URLSessionDataTask?
    var userData = UserDefaults.standard.dictionary(forKey: "userData")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 設定大頭照
        self.setPhoto(self.userData!["userImageURL"] as! String)
    }

    @IBAction func goLogout(_ sender: Any) {
        // 未登入
        if FIRAuth.auth()?.currentUser == nil {
            self.showMsg("未登入", showMsgStatus: .loginSuccess, handler: nil)
        }
        
        do {
            try FIRAuth.auth()?.signOut()
            self.showMsg("登出成功", showMsgStatus: .loginSuccess, handler: self.handler)
        } catch let error as NSError {
            self.showMsg((error.localizedDescription), showMsgStatus: .loginFail, handler: nil)
        }
        
    }
    
    // 變更的大頭照
    @IBAction func changeImage(_ sender: Any) {
        // 啟用相機
        // 建立一個 UIImagePickerController 的實體
        let imagePickerController = UIImagePickerController()
        
        // 委任代理
        imagePickerController.delegate = self
        
        // 設定 UIAlertController 的標題與樣式為動作清單(ActionSheet)
        let imagePickerAlertController = UIAlertController(title: "變更圖片", message: "請選擇要上傳的圖片或啟用相機", preferredStyle: .actionSheet)
        
        // 開啟圖庫，生成 UIAlertController 和 Action Sheet 的動作
        let imageFromLibAction = UIAlertAction(title: "照片圖庫", style: .default) { (Void) in
            
            // 判斷是否可以從照片圖庫取得照片來源
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                
                // 如果可以，指定 UIImagePickerController 的照片來源為 照片圖庫 (.photoLibrary)，並 present UIImagePickerController
                imagePickerController.sourceType = .photoLibrary
                self.present(imagePickerController, animated: true, completion: nil)
            }
        }
        
        // 啟用相機，生成 UIAlertController 和 Action Sheet 的動作
        let imageFromCameraAction = UIAlertAction(title: "相機", style: .default) { (Void) in
            
            // 判斷是否可以從相機取得照片來源
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                
                // 如果可以，指定 UIImagePickerController 的照片來源為 照片圖庫 (.camera)，並 present UIImagePickerController
                imagePickerController.sourceType = .camera
                self.present(imagePickerController, animated: true, completion: nil)
            }
        }
        
        // 新增一個取消動作，讓使用者可以關閉 UIAlertController
        let cancelAction = UIAlertAction(title: "取消", style: .cancel) { (Void) in
            
            imagePickerAlertController.dismiss(animated: true, completion: nil)
        }
        
        imagePickerAlertController.addAction(imageFromLibAction)
        imagePickerAlertController.addAction(imageFromCameraAction)
        imagePickerAlertController.addAction(cancelAction)
        
        // 當使用者按下 uploadBtnAction 時會 present 剛剛建立好的三個 UIAlertAction 動作與處理的 block
        present(imagePickerAlertController, animated: true, completion: nil)
    }
    
    // 從相簿或相機取到照片
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        var selectedImageFromPicker: UIImage?
        
        // 取得從 UIImagePickerController 選擇到的檔案
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            selectedImageFromPicker = pickedImage
        }
        
        // 關閉圖庫
        dismiss(animated: true, completion: nil)
        
        // 將照片上傳到 Storage 
        if let selectedImage = selectedImageFromPicker {
            print("\(selectedImage)")
            
            // 從 UserDefaults 取得登入者的 ID，該 ID 會被用來當成照片的檔名
            let userId = (UserDefaults.standard.dictionary(forKey: "userData"))?["userId"] as! String
            
            // 第一個 child 的參數為「目錄名稱」；第二個 child 的參數為「圖片名稱」
            let storageRef = FIRStorage.storage().reference().child("UserImages").child("\(userId).png")
            
            // 將圖片轉成 png 後上傳到 storage
            if let uploadData = UIImagePNGRepresentation(selectedImage) {
                // 將圖片上傳至 Storage
                storageRef.put(uploadData, metadata: nil, completion: { (data, error) in
                    
                    if error != nil {
                        print("Error: \(error!.localizedDescription)")
                        return
                    }
                    
                    // 取得上傳圖片連結的方式
                    if let uploadImageUrl = data?.downloadURL()?.absoluteString {
                        
                        // 上傳照片的連結
                        print("Photo Url: \(uploadImageUrl)")
                        
                        // 更新 Users 的大頭照連結資料
                        let reference: FIRDatabaseReference! = FIRDatabase.database().reference().child("Users").child((UserDefaults.standard.dictionary(forKey: "userData"))?["userId"] as! String)
                        var userDataRemote: [String : AnyObject] = [String : AnyObject]()
                        userDataRemote["userId"] = (UserDefaults.standard.dictionary(forKey: "userData"))?["userId"] as AnyObject
                        userDataRemote["userEmail"] = (UserDefaults.standard.dictionary(forKey: "userData"))?["userEmail"] as AnyObject
                        userDataRemote["userImageURL"] = uploadImageUrl as AnyObject
                        userDataRemote["createDate"] = "20170507" as AnyObject
                        
                        reference.updateChildValues(userDataRemote) { (err, ref) in
                            if err != nil {
                                print("err： \(err!)")
                                return
                            }
                            
                            print(ref.description())
                            
                            // 變更大頭照
                            self.setPhoto(uploadImageUrl)
                        }
                    }
                })
            }
        }        
    }
    
    // 註冊成功關閉此頁面
    func handler() -> Void {
        self.dismiss(animated: true, completion: nil)
    }
    
    // 設定大頭照
    func setPhoto(_ userImageURL: String) {
        if userImageURL != "none" {
            let session = URLSession.shared
            dataTask = session.dataTask(with: URL(string: userImageURL)!, completionHandler: {
                (data, response, error) in
                if let error = error {
                    print("\(error.localizedDescription)")
                    return
                } else if let httpResponse = response as? HTTPURLResponse {
                    // storage 的權限如果沒有打開的話，會出現 403 的錯誤
                    if httpResponse.statusCode == 200 {
                        DispatchQueue.main.async() {
                            if let data = data {
                                self.userImage.image = UIImage(data: data)
                            }
                        }
                    }
                }
            })
        }
        dataTask?.resume()
    }

}
