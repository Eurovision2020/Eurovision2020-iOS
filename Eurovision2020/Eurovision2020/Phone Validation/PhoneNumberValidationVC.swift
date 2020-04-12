//
//  PhoneNumberValidationVC.swift
//  Eurovision2020
//
//  Created by Sacha DSO on 07/04/2020.
//  Copyright © 2020 MarsacProductions. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import PhoneNumberKit

class PhoneNumberValidationVC: UIViewController {
    
    let phoneNumberKit = PhoneNumberKit()
    
    var v = PhoneNumberValidationView()
    override func loadView() {
        view = v
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Phone Number Validation"
        v.okButton.isEnabled = false
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        v.blurredEffectView.addGestureRecognizer(tap)
     
        on("INJECTION_BUNDLE_NOTIFICATION") {
            self.v = PhoneNumberValidationView()
            self.view = self.v
        }
        
        v.okButton.addTarget(self, action: #selector(okTapped), for: .touchUpInside)
        
        
        
        let countryCode = Locale.current.regionCode!
//
//        if countryCode == "FR" {
//            v.phoneNumberField.text = "+33"
//        } else if countryCode == "US" {
//            v.phoneNumberField.text = "+1 456"
//        }
        
        v.phoneNumberField.addTarget(self, action: #selector(phoneNumberChanged), for: .editingChanged)
    }
    
    @objc
    func phoneNumberChanged() {
        guard let phoneNumberString = v.phoneNumberField.text else {
            return
        }
        let phoneNumber = try? phoneNumberKit.parse(phoneNumberString)
        v.okButton.isEnabled = (phoneNumber != nil)
    }
    
    @objc
    func tapped() {
        view.endEditing(true)
    }
    
    @objc
    func okTapped() {
        guard let phoneNumberString = v.phoneNumberField.text else {
            return
        }
        guard let phoneNumber = try? phoneNumberKit.parse(phoneNumberString) else {
            return
        }
    
//            PhoneNumber(numberString: "+33778127906",
//            countryCode: 33,
//            leadingZero: false,
//            nationalNumber: 778127906,
//            numberExtension: nil,
//            type: PhoneNumberKit.PhoneNumberType.mobile,
//            regionID: Optional("FR"))
        
        
        // Localize sms sent to user's laguage
        Auth.auth().languageCode = Locale.current.languageCode ?? "en"
        
        // Start SMS confirmation
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber.numberString, uiDelegate: nil) { [weak self] (verificationID, error) in
            guard let verificationID = verificationID else {
                print(error)
                return
            }

            // Ask for SMS confirmation code.
            let alert = UIAlertController(title: "SMS confirmation",
                                          message: "Confim your phone number by entering the code received via SMS",
                                          preferredStyle: UIAlertController.Style.alert)
            alert.addTextField { $0.placeholder = "SMS Code" }
            alert.addAction(UIAlertAction(title: "Confirm", style: .default, handler: { a in
                if let smsCode = alert.textFields?.first?.text {
                    // Confirm Phone number with both verificationID amd SMS code.
                    self?.authWith(id: verificationID, code: smsCode)
                }
            }))
            self?.present(alert, animated: true, completion: nil)
        }
    }
    
    func authWith(id: String, code: String) {
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: id, verificationCode: code)
        Auth.auth().signIn(with: credential) { [weak self] (authResult, error) in
            
            print("authResult \(authResult)")
            print("error \(error)")
            
            if error == nil {
                self?.navigationController?.pushViewController(VotingVC(), animated: true)
            }
        }
    }
}
