public import RFC_2045

extension RFC_2045.ContentType: Encodable, Decodable {

    private enum CodingKeys: String, CodingKey {

        case type

        case subtype

        case parameters
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        let subtype = try container.decode(String.self, forKey: .subtype)
        let parameters =
            try container.decodeIfPresent([String: String].self, forKey: .parameters) ?? [:]

        var named: [RFC_2045.Parameter.Name: String] = [:]
        named.reserveCapacity(parameters.count)
        for (name, value) in parameters {
            let key = try RFC_2045.Parameter.Name(name)
            named[key] = value
        }

        try self.init(type: type, subtype: subtype, parameters: named)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(subtype, forKey: .subtype)

        var parameters: [String: String] = [:]
        parameters.reserveCapacity(self.parameters.count)
        for (name, value) in self.parameters {
            parameters[name.rawValue] = value
        }

        try container.encode(parameters, forKey: .parameters)
    }
}
