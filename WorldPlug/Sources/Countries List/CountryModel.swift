//
//  CountryModel.swift
//  WorldPlug
//
//  Created by Antonino Musolino on 03/04/24.
//

import Foundation

struct Country: Identifiable, Decodable {
    var id: String {
        code
    }
    
    let name: String
    let code: String
    let voltage: String
    let frequency: String
    let flagUnicode: String
    let plugTypes: [String]

    var localizedName: String {
        Locale.current.localizedString(forRegionCode: code) ?? ""
    }

    enum CodingKeys: String, CodingKey {
        case name
        case code = "country_code"
        case voltage
        case frequency
        case flagUnicode = "flag_emoji"
        case plugTypes = "plug_types"
    }
}
