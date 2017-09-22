//
//  ViewController.swift
//  Currency
//
//  Created by Grisha on 14.09.17.
//  Copyright © 2017 Grisha. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var settext: UILabel!
    @IBOutlet weak var gettext: UITextField!

    @IBAction func exchange(_ sender: UIButton) {
        let amount1 = Double(gettext.text!)
        let result1 = Double(label.text!)
        let exchange = amount1! * result1!
        let stringexch = String(exchange)
        settext.text = stringexch
    }
    
    @IBOutlet weak var pickerFrom: UIPickerView!
    @IBOutlet weak var pickerTo: UIPickerView!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var currencies = ["RON", "MYR", "CAD", "DKK", "GBP", "PHP", "CZK", "PLN", "RUB", "SGD", "BRL", "JPY", "SEK", "USD", "HRK", "NZD", "HKD", "BGN", "TRY", "MXN", "HUF", "KRW", "NOK", "INR", "ILS", "IDR", "CHF", "THB", "CNY", "ZAR", "AUD"]
    
    //Ниже метод который парсит названия валют и добавляет их в пустой массив.
    //Но из-за того что не успел с многопоточностью не могу заменить его на массив который выше
    var allcurrencies = [String]()
    func parseCurrencies() -> [String] {
        let url = URL(string: "https://api.fixer.io/latest")
        let task = URLSession.shared.dataTask(with: url!) { (data, response, error) in
            if error != nil {
                print("error")
            } else {
                if let mydata = data {
                    do {
                        let myJson = try JSONSerialization.jsonObject(with: mydata, options: JSONSerialization.ReadingOptions.mutableContainers) as AnyObject
                        
                        if let rates = myJson["rates"] as? Dictionary<String, Double> {
                            
                            for (key, _) in rates {
                                self.allcurrencies.append(key)
                                print(self.allcurrencies)
                            }
                            
                        }
                        
                    }
                    catch {
                        
                    }
                }
            }
            
        }
        task.resume()
        return allcurrencies
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.pickerTo.dataSource = self
        self.pickerFrom.dataSource = self
        
        self.pickerTo.delegate = self
        self.pickerFrom.delegate = self
        
        self.activityIndicator.hidesWhenStopped = true
        self.requestCurrentCurrencyRate()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        if pickerView === pickerTo {
            return self.currenciesExeptBase().count
        }
        return currencies.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView === pickerTo {
            return self.currenciesExeptBase()[row]
        }
        return currencies[row]
    }
    
    func requestCurrentCurrencyRate(){
        self.activityIndicator.startAnimating()
        self.label.text = ""
        
        let baseCurrencyIndex = self.pickerFrom.selectedRow(inComponent: 0)
        let toCurrencyIndex = self.pickerTo.selectedRow(inComponent: 0)
        
        let baseCurrency = self.currencies[baseCurrencyIndex]
        let toCurrency = self.currenciesExeptBase()[toCurrencyIndex]
        
  
        self.retrieveCurrencyRate(baseCurrency: baseCurrency, toCurrency: toCurrency) {[weak self] (value) in
                DispatchQueue.main.async(execute: {
                    if let strongSelf = self {
                        strongSelf.label.text = value
                        strongSelf.activityIndicator.stopAnimating()
                }
            })
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView === pickerFrom {
            self.pickerTo.reloadAllComponents()
        }
        
        self.requestCurrentCurrencyRate()
    }
    
    func currenciesExeptBase() -> [String] {
        var currenciesExceptBase = currencies
        currenciesExceptBase.remove(at: pickerFrom.selectedRow(inComponent: 0))
        
        return currenciesExceptBase
    }
    
    func requestCurrencyRates(baseCurrency: String, parseHandler: @escaping (Data?, Error?) -> Void) {
        let url = URL(string: "https://api.fixer.io/latest?base=" + baseCurrency)!
        
        let dataTask = URLSession.shared.dataTask(with: url) {
            (dataRecieved, response, error) in parseHandler(dataRecieved, error)
        }
        dataTask.resume()
    }
    
    func parseCurrencyRatesResponse(data: Data?, toCurrency: String) -> String {
        var value: String = ""
       
        do {
            let json = try JSONSerialization.jsonObject(with: data!, options: []) as? Dictionary<String, Any>
            if let parsedJSON = json {
                print("\(parsedJSON)")
                if let rates = parsedJSON["rates"] as? Dictionary<String, Double>{
                /*    for (key, _) in rates {
                        allcurrencies.append(key)} */
                    if let rate = rates[toCurrency]{
                        value = "\(rate)"
                    } else {
                        value = "No rate for currency \"\(toCurrency)\" found"
                    }
                } else {
                    value = "No \"rates\" field found"
                }
            } else {
                value = "No JSON value parsed"
            }
            
        } catch {
            value = error.localizedDescription
        }
        return value
        
    }
    
    
    
    
    func retrieveCurrencyRate(baseCurrency: String, toCurrency: String, completion: @escaping (String) -> Void) {
        self.requestCurrencyRates(baseCurrency: baseCurrency) { [weak self] (data, error) in
            var string = "No currency retrieved!"
            
            if let currentError = error {
                string = currentError.localizedDescription
            } else {
                if let strongSelf = self {
                    string = strongSelf.parseCurrencyRatesResponse(data: data, toCurrency: toCurrency)
                }
            }
            completion(string)
        }
    }

    

}

