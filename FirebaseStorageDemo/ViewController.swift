//
//  ViewController.swift
//  FirebaseStorageDemo
//
//  Created by Frank.Chen on 2017/5/7.
//  Copyright © 2017年 Frank.Chen. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

class ViewController: UIViewController {

    @IBOutlet weak var emailTxtFld: UITextField!
    @IBOutlet weak var passwordTxtFld: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
        
    // 登入
    @IBAction func goUploadImage(_ sender: Any) {
        FIRAuth.auth()?.signIn(withEmail: self.emailTxtFld.text!, password: self.passwordTxtFld.text!) { (user, error) in
            // 登入失敗
            if error != nil {
                self.showMsg((error?.localizedDescription)!, showMsgStatus: .loginFail, handler: nil)
                return
            }                        
            
            // 至 database 依使用者 ID 取得其資料並存放在 UserDefault 裡供整個應用程式使用            
            let reference: FIRDatabaseReference! = FIRDatabase.database().reference().child("Users").child((user?.uid)!)
            
            reference.queryOrderedByKey().observe(.value, with: { [weak self] (snapshot) in
                if snapshot.childrenCount > 0 {
                    
                    let snapshotValue: [String: AnyObject] = snapshot.value as! [String: AnyObject]
                    
                    // 將登入的 user 存放在 UserDefault
                    var userData: [String : Any] = [String : Any]()
                    userData["userId"] = snapshotValue["userId"]
                    userData["userEmail"] = snapshotValue["userEmail"]
                    userData["userImageURL"] = snapshotValue["userImageURL"]
                    UserDefaults.standard.set(userData, forKey: "userData")
                    
                    // 登入成功
                    self?.performSegue(withIdentifier: "uploadImageSegue", sender: nil)
                }
            })              
        }
    }    
}


extension UIViewController {
    // 提示錯誤訊息
    func showMsg(_ message: String, showMsgStatus: ShowMsgStatus, handler: (() -> Swift.Void)? = nil) {
        let alertController = UIAlertController(title: "提示", message: message, preferredStyle: .alert)
        let cancel: UIAlertAction!
        
        switch showMsgStatus {
        case .loginSuccess:
            cancel = UIAlertAction(title: "確定", style: .default) { action in
                handler!()
            }
        default:
            cancel = UIAlertAction(title: "確定", style: .default, handler: nil)
        }
        
        alertController.addAction(cancel)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    // 註冊tab事件，點選瑩幕任一處可關閉瑩幕小鍵盤
    func addTapGestureRecognizer() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        self.view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard() {
        self.view.endEditing(true)
    }
}

enum ShowMsgStatus {
    case loginSuccess
    case loginFail
}
