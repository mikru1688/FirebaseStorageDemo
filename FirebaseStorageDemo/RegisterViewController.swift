//
//  RegisterViewController.swift
//  FirebaseStorageDemo
//
//  Created by Frank.Chen on 2017/5/7.
//  Copyright © 2017年 Frank.Chen. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

class RegisterViewController: UIViewController {

    @IBOutlet weak var emailTxtFld: UITextField!
    @IBOutlet weak var passwordTxtFld: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // 註冊
    @IBAction func goRegister(_ sender: Any) {
        // email和密碼為必填欄位
        if self.emailTxtFld.text == "" || self.passwordTxtFld.text == "" {
            super.showMsg("請輸入email和密碼", showMsgStatus: .loginFail, handler: nil)
            return
        }
        
        // 建立帳號
        FIRAuth.auth()?.createUser(withEmail: self.emailTxtFld.text!, password: self.passwordTxtFld.text!) { (user, error) in
            
            // 註冊失敗
            if error != nil {
                self.showMsg((error?.localizedDescription)!, showMsgStatus: .loginFail, handler: nil)
                return
            }
                        
            // 將登入的 user 寫入 database
            let reference: FIRDatabaseReference! = FIRDatabase.database().reference().child("Users").child((user?.uid)!)
            var userDataRemote: [String : AnyObject] = [String : AnyObject]()
            userDataRemote["userId"] = (user?.uid)! as AnyObject
            userDataRemote["userEmail"] = (user?.email)! as AnyObject
            userDataRemote["userImageURL"] = "none" as AnyObject
            userDataRemote["createDate"] = "20170507" as AnyObject
            
            reference.updateChildValues(userDataRemote) { (err, ref) in
                if err != nil {
                    print("err： \(err!)")
                    return
                }
                
                print(ref.description())
            }
            
            // 註冊成功並返回首頁
            super.showMsg("註冊成功", showMsgStatus: .loginSuccess, handler: self.handler)
        }
    }
    
    // 返回
    @IBAction func goBack(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // 註冊成功關閉此頁面
    func handler() -> Void {
        self.dismiss(animated: true, completion: nil)
    }
}
