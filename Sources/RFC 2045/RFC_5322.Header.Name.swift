public import RFC_5322

extension RFC_5322.Header.Name {

    public static let contentType: Self = .init(__unchecked: (), rawValue: "Content-Type")

    public static let contentTransferEncoding: Self = .init(
        __unchecked: (),
        rawValue: "Content-Transfer-Encoding"
    )

    public static let mimeVersion: Self = .init(__unchecked: (), rawValue: "MIME-Version")

    public static let contentId: Self = .init(__unchecked: (), rawValue: "Content-ID")

    public static let contentDescription: Self = .init(
        __unchecked: (),
        rawValue: "Content-Description"
    )
}
