######## START OF CONFIGURABLE OPTIONS ##########
$subject = "acme.example.com"
$lifeTimeDays = 365*2
$keySize = 2048

$useSHA256 = $true
#$useSHA256 = $false
# The default SHA1 algorithm is more compatible but less secure then SHA256

######## END OF CONFIGURABLE OPTIONS ##########

# The following area includes the enumerations used with the interfaces
$AlternativeNameType = @{
XCN_CERT_ALT_NAME_UNKNOWN = 0
XCN_CERT_ALT_NAME_OTHER_NAME = 1
XCN_CERT_ALT_NAME_RFC822_NAME = 2
XCN_CERT_ALT_NAME_DNS_NAME = 3
XCN_CERT_ALT_NAME_DIRECTORY_NAME = 5
XCN_CERT_ALT_NAME_URL = 7
XCN_CERT_ALT_NAME_IP_ADDRESS = 8
XCN_CERT_ALT_NAME_REGISTERED_ID = 9
XCN_CERT_ALT_NAME_GUID = 10
XCN_CERT_ALT_NAME_USER_PRINCIPLE_NAME = 11
}

$ObjectIdGroupId = @{
XCN_CRYPT_ANY_GROUP_ID = 0
XCN_CRYPT_HASH_ALG_OID_GROUP_ID = 1
XCN_CRYPT_ENCRYPT_ALG_OID_GROUP_ID = 2
XCN_CRYPT_PUBKEY_ALG_OID_GROUP_ID = 3
XCN_CRYPT_SIGN_ALG_OID_GROUP_ID = 4
XCN_CRYPT_RDN_ATTR_OID_GROUP_ID = 5
XCN_CRYPT_EXT_OR_ATTR_OID_GROUP_ID = 6
XCN_CRYPT_ENHKEY_USAGE_OID_GROUP_ID = 7
XCN_CRYPT_POLICY_OID_GROUP_ID = 8
XCN_CRYPT_TEMPLATE_OID_GROUP_ID = 9
XCN_CRYPT_LAST_OID_GROUP_ID = 9
XCN_CRYPT_FIRST_ALG_OID_GROUP_ID = 1
XCN_CRYPT_LAST_ALG_OID_GROUP_ID = 4
XCN_CRYPT_OID_DISABLE_SEARCH_DS_FLAG = 0x80000000
XCN_CRYPT_KEY_LENGTH_MASK = 0xffff0000
}

$X509KeySpec = @{
XCN_AT_NONE = 0 # The intended use is not identified.
# This value should be used if the provider is a
# Cryptography API: Next Generation (CNG) key storage provider (KSP).
XCN_AT_KEYEXCHANGE = 1 # The key can be used for encryption or key exchange.
XCN_AT_SIGNATURE = 2 # The key can be used for signing.
}

$X509PrivateKeyExportFlags = @{
XCN_NCRYPT_ALLOW_EXPORT_NONE = 0
XCN_NCRYPT_ALLOW_EXPORT_FLAG = 0x1
XCN_NCRYPT_ALLOW_PLAINTEXT_EXPORT_FLAG = 0x2
XCN_NCRYPT_ALLOW_ARCHIVING_FLAG = 0x4
XCN_NCRYPT_ALLOW_PLAINTEXT_ARCHIVING_FLAG = 0x8
}

$X509PrivateKeyUsageFlags = @{
XCN_NCRYPT_ALLOW_USAGES_NONE = 0
XCN_NCRYPT_ALLOW_DECRYPT_FLAG = 0x1
XCN_NCRYPT_ALLOW_SIGNING_FLAG = 0x2
XCN_NCRYPT_ALLOW_KEY_AGREEMENT_FLAG = 0x4
XCN_NCRYPT_ALLOW_ALL_USAGES = 0xffffff
}

$X509CertificateEnrollmentContext = @{
ContextUser = 0x1
ContextMachine = 0x2
ContextAdministratorForceMachine = 0x3
}

$X509KeyUsageFlags = @{
DIGITAL_SIGNATURE = 0x80 # Used with a Digital Signature Algorithm (DSA)
# to support services other than nonrepudiation,
# certificate signing, or revocation list signing.
KEY_ENCIPHERMENT = 0x20 # Used for key transport.
DATA_ENCIPHERMENT = 0x10 # Used to encrypt user data other than cryptographic keys.
}

$EncodingType = @{
XCN_CRYPT_STRING_BASE64HEADER = 0
XCN_CRYPT_STRING_BASE64 = 0x1
XCN_CRYPT_STRING_BINARY = 0x2
XCN_CRYPT_STRING_BASE64REQUESTHEADER = 0x3
XCN_CRYPT_STRING_HEX = 0x4
XCN_CRYPT_STRING_HEXASCII = 0x5
XCN_CRYPT_STRING_BASE64_ANY = 0x6
XCN_CRYPT_STRING_ANY = 0x7
XCN_CRYPT_STRING_HEX_ANY = 0x8
XCN_CRYPT_STRING_BASE64X509CRLHEADER = 0x9
XCN_CRYPT_STRING_HEXADDR = 0xa
XCN_CRYPT_STRING_HEXASCIIADDR = 0xb
XCN_CRYPT_STRING_HEXRAW = 0xc
XCN_CRYPT_STRING_NOCRLF = 0x40000000
XCN_CRYPT_STRING_NOCR = 0x80000000
}

$InstallResponseRestrictionFlags = @{
AllowNone = 0x00000000
AllowNoOutstandingRequest = 0x00000001
AllowUntrustedCertificate = 0x00000002
AllowUntrustedRoot = 0x00000004
}

$X500NameFlags = @{
XCN_CERT_NAME_STR_NONE = 0
XCN_CERT_SIMPLE_NAME_STR = 1
XCN_CERT_OID_NAME_STR = 2
XCN_CERT_X500_NAME_STR = 3
XCN_CERT_XML_NAME_STR = 4
XCN_CERT_NAME_STR_SEMICOLON_FLAG = 0x40000000
XCN_CERT_NAME_STR_NO_PLUS_FLAG = 0x20000000
XCN_CERT_NAME_STR_NO_QUOTING_FLAG = 0x10000000
XCN_CERT_NAME_STR_CRLF_FLAG = 0x8000000
XCN_CERT_NAME_STR_COMMA_FLAG = 0x4000000
XCN_CERT_NAME_STR_REVERSE_FLAG = 0x2000000
XCN_CERT_NAME_STR_FORWARD_FLAG = 0x1000000
XCN_CERT_NAME_STR_DISABLE_IE4_UTF8_FLAG = 0x10000
XCN_CERT_NAME_STR_ENABLE_T61_UNICODE_FLAG = 0x20000
XCN_CERT_NAME_STR_ENABLE_UTF8_UNICODE_FLAG = 0x40000
XCN_CERT_NAME_STR_FORCE_UTF8_DIR_STR_FLAG = 0x80000
XCN_CERT_NAME_STR_DISABLE_UTF8_DIR_STR_FLAG = 0x100000
}

$ObjectIdPublicKeyFlags = @{
XCN_CRYPT_OID_INFO_PUBKEY_ANY = 0
XCN_CRYPT_OID_INFO_PUBKEY_SIGN_KEY_FLAG = 0x80000000
XCN_CRYPT_OID_INFO_PUBKEY_ENCRYPT_KEY_FLAG = 0x40000000
}

$AlgorithmFlags = @{
AlgorithmFlagsNone = 0
AlgorithmFlagsWrap = 0x1
}

# Only the following RDNs are supported in the subject name
# IX500DistinguishedName Interface
# http://msdn.microsoft.com/en-us/library/aa377051%28v=VS.85%29.aspx
# C, CN, E, EMAIL, DC, G, GivenName, I, L, O, OU, S, ST, STREET, SN, T, TITLE

# Note we build the subject as CN=subject
$subjectName = "CN=" + $subject
$objSubjectDN = New-Object -ComObject X509Enrollment.CX500DistinguishedName
$objSubjectDN.Encode($subjectName, $X500NameFlags.XCN_CERT_NAME_STR_NONE)

# Build a private key
$objKey = New-Object -ComObject X509Enrollment.CX509PrivateKey
$objKey.ProviderName = "Microsoft RSA SChannel Cryptographic Provider"
$objKey.KeySpec = $X509KeySpec.XCN_AT_KEYEXCHANGE
$objKey.KeyUsage = $X509PrivateKeyUsageFlags.XCN_NCRYPT_ALLOW_ALL_USAGES
$objKey.Length = $keySize
$objKey.MachineContext = $TRUE
$objKey.ExportPolicy = $X509PrivateKeyExportFlags.XCN_NCRYPT_ALLOW_PLAINTEXT_EXPORT_FLAG
$objKey.Create()

# Add the Server Authentication EKU OID
$objServerAuthenticationOid = New-Object -ComObject X509Enrollment.CObjectId
$strServerAuthenticationOid = "1.3.6.1.5.5.7.3.1"
$objServerAuthenticationOid.InitializeFromValue($strServerAuthenticationOid)

$objEkuoids = New-Object -ComObject X509Enrollment.CObjectIds
$objEkuoids.add($objServerAuthenticationOid)
$objEkuext = New-Object -ComObject X509Enrollment.CX509ExtensionEnhancedKeyUsage
$objEkuext.InitializeEncode($objEkuoids)

# Set the Key Usage to Key Encipherment and Digital Signature
$keyUsageExt = New-Object -ComObject X509Enrollment.CX509ExtensionKeyUsage
$keyUsageExt.InitializeEncode($X509KeyUsageFlags.KEY_ENCIPHERMENT -bor `
$X509KeyUsageFlags.DIGITAL_SIGNATURE )

$strTemplateName = "" # We don't use a certificate template
$cert = New-Object -ComObject X509Enrollment.CX509CertificateRequestCertificate
# Notice we use $X509CertificateEnrollmentContext.ContextMachine
$cert.InitializeFromPrivateKey($X509CertificateEnrollmentContext.ContextMachine, `
   $objKey, `
   $strTemplateName)
$cert.X509Extensions.Add($keyUsageExt)
$cert.Subject = $objSubjectDN
$cert.Issuer = $cert.Subject

if ($useSHA256)
{
  # Set the hash algorithm to sha256 instead of the default sha1
  $hashAlgorithmObject = New-Object -ComObject X509Enrollment.CObjectId
  $hashAlgorithmObject.InitializeFromAlgorithmName( `
  $ObjectIdGroupId.XCN_CRYPT_HASH_ALG_OID_GROUP_ID, `
  $ObjectIdPublicKeyFlags.XCN_CRYPT_OID_INFO_PUBKEY_ANY, `
  $AlgorithmFlags.AlgorithmFlagsNone, "SHA256")
  $cert.HashAlgorithm = $hashAlgorithmObject
}

# We subtract one day from the start time to avoid timezone or other 
#   time issues where cert is not yet valid
$SubtractDays = New-Object System.TimeSpan 1, 0, 0, 0, 0
$curdate = get-date
$cert.NotBefore = $curdate.Subtract($SubtractDays)
$cert.NotAfter = $cert.NotBefore.AddDays($lifeTimeDays)
$cert.X509Extensions.Add($objEkuext)
$cert.Encode()

# Now we create the cert from the request we have built up and 
#   install it into the certificate store
$enrollment = New-Object -ComObject X509Enrollment.CX509Enrollment
$enrollment.InitializeFromRequest($cert)
$certdata = $enrollment.CreateRequest($EncodingType.XCN_CRYPT_STRING_BASE64HEADER)
$strPassword = ""
$enrollment.InstallResponse($InstallResponseRestrictionFlags.AllowUntrustedCertificate, `
  $certdata, $EncodingType.XCN_CRYPT_STRING_BASE64HEADER, $strPassword)