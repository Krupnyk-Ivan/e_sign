package com.example.e_sign

import android.content.ContentValues
import android.provider.MediaStore
import java.io.IOException
import org.bouncycastle.cert.X509CertificateHolder
import org.bouncycastle.cms.CMSProcessableByteArray
import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.KeyStore
import java.security.PrivateKey
import java.security.Signature
import java.security.MessageDigest
import java.security.cert.X509Certificate
import java.io.FileInputStream
import android.util.Base64
import android.util.Log
import org.bouncycastle.jce.provider.BouncyCastleProvider
import java.security.Security
import java.io.File
import java.math.BigInteger
import java.io.FileOutputStream
import java.util.Date
import org.bouncycastle.cms.*
import org.bouncycastle.cert.jcajce.JcaCertStore
import org.bouncycastle.operator.jcajce.JcaContentSignerBuilder
import org.bouncycastle.operator.jcajce.JcaDigestCalculatorProviderBuilder
import org.bouncycastle.cms.jcajce.JcaSignerInfoGeneratorBuilder
import org.bouncycastle.cert.jcajce.JcaX509CertificateConverter
import org.bouncycastle.cms.jcajce.JcaSimpleSignerInfoVerifierBuilder
import org.bouncycastle.cms.SignerInformation
import org.bouncycastle.util.Selector
import org.bouncycastle.cms.CMSSignedData
class MainActivity: FlutterActivity() {
   
    private val CHANNEL = "document_signer"
    private val TAG = "JKSSigner"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "signWithJKS" -> {
                    try {
                        val fileBytes = call.argument<ByteArray>("fileBytes")
                        val keystorePath = call.argument<String>("keystorePath")
                        val password = call.argument<String>("password")
                        val alias = call.argument<String>("alias")
                        
                        if (fileBytes == null || keystorePath == null || password == null || alias == null) {
                            result.error("INVALID_ARGS", "Missing required arguments", null)
                            return@setMethodCallHandler
                        }
                        
                        val signResult = signWithJKS(fileBytes, keystorePath, password, alias)
                        result.success(signResult)
                        
                    } catch (e: Exception) {
                        Log.e(TAG, "Error signing with JKS", e)
                        result.error("SIGNING_ERROR", e.message, null)
                    }
                }
                
            "pfxExists" -> {
    val alias = call.argument<String>("alias") ?: return@setMethodCallHandler result.error("NO_ALIAS", "Alias required", null)
    val file = File(context.cacheDir, "$alias.pfx")
    result.success(file.exists())
}

   "generatePfx" -> {
    try {
        val password = call.argument<String>("password") ?: throw Exception("Password is required")
        val alias = call.argument<String>("alias") ?: "mykey"
        val userId = call.argument<String>("userId") ?: "userId"
             Log.d(TAG, "PFX generated at: ${userId}")

        val pfxPath = generatePfx(password, alias,userId)
        result.success(pfxPath)
    } catch (e: Exception) {

        Log.e(TAG, "Error generating PFX", e)
        result.error("PFX_ERROR", e.message, null)
    }
}
"verifySignature" -> {
    try {
        val originalPath = call.argument<String>("originalPath")
        val signaturePath = call.argument<String>("signaturePath")

        if (originalPath == null || signaturePath == null) {
            result.error("INVALID_ARGS", "Missing file paths", null)
            return@setMethodCallHandler
        }

        val isValid = verifySignature(File(originalPath), File(signaturePath))
        result.success(isValid)
    } catch (e: Exception) {
        Log.e(TAG, "Signature verification failed", e)
        result.error("VERIFY_ERROR", e.message, null)
    }
}


            }
        }
    }
private fun generatePfx(password: String, alias: String, userId: String): String {
    Security.addProvider(BouncyCastleProvider())

    val keyPairGenerator = java.security.KeyPairGenerator.getInstance("RSA")
    keyPairGenerator.initialize(2048)
    val keyPair = keyPairGenerator.generateKeyPair()

    val cert = generateSelfSignedCertificate(keyPair, "CN=$userId")

    val keystore = KeyStore.getInstance("PKCS12")
    keystore.load(null, null)
    keystore.setKeyEntry(alias, keyPair.private, password.toCharArray(), arrayOf(cert))

    val pfxFile = File(cacheDir, "$alias.pfx")
    FileOutputStream(pfxFile).use { fos ->
        keystore.store(fos, password.toCharArray())
    }
    Log.d(TAG, "PFX generated at: ${pfxFile.absolutePath}")

    val resolver = context.contentResolver
    val collection = MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
    val fileName = "$alias.pfx"
    val mimeType = "application/x-pkcs12"

    val contentValues = ContentValues().apply {
        put(MediaStore.Downloads.DISPLAY_NAME, fileName)
        put(MediaStore.Downloads.MIME_TYPE, mimeType)
        put(MediaStore.Downloads.IS_PENDING, 1)
    }

    val fileUri = resolver.insert(collection, contentValues)
        ?: throw IOException("Failed to create file in Downloads")

    resolver.openOutputStream(fileUri).use { outputStream ->
        outputStream?.write(pfxFile.readBytes())
    }

    contentValues.clear()
    contentValues.put(MediaStore.Downloads.IS_PENDING, 0)
    resolver.update(fileUri, contentValues, null, null)

    Log.d(TAG, "PFX file copied to Downloads: $fileUri")

    return pfxFile.absolutePath
}

private fun generateSelfSignedCertificate(keyPair: java.security.KeyPair, dn: String): X509Certificate {
    val certGen = org.bouncycastle.x509.X509V3CertificateGenerator()
    val startDate = Date()
    val endDate = Date(System.currentTimeMillis() + 365L * 24 * 60 * 60 * 1000) 

    certGen.setSerialNumber(BigInteger.valueOf(System.currentTimeMillis()))
    certGen.setSubjectDN(javax.security.auth.x500.X500Principal(dn))
    certGen.setIssuerDN(javax.security.auth.x500.X500Principal(dn))
    certGen.setNotBefore(startDate)
    certGen.setNotAfter(endDate)
    certGen.setPublicKey(keyPair.public)
    certGen.setSignatureAlgorithm("SHA256withRSA")

    return certGen.generate(keyPair.private)
}
fun verifySignature(originalFile: File, signatureFile: File): Boolean {
   Security.addProvider(BouncyCastleProvider())

    try {
        val originalBytes = originalFile.readBytes()
        val signatureBytes = signatureFile.readBytes()

        val cmsData = CMSSignedData(signatureBytes)
        
        val contentToVerify = CMSProcessableByteArray(originalBytes)
        
        val signedDataWithContent = CMSSignedData(contentToVerify, signatureBytes)
        
        val signers = signedDataWithContent.signerInfos.signers
        val certs = signedDataWithContent.certificates
        
        for (signer in signers) {
            val allCerts = certs.getMatches(null)
            var matchingCert: X509CertificateHolder? = null
            
            for (certObj in allCerts) {
                val certHolder = certObj as X509CertificateHolder
                if (signer.sid.match(certHolder)) {
                    matchingCert = certHolder
                    break
                }
            }
            
            if (matchingCert == null) continue
            val cert = JcaX509CertificateConverter()
                .getCertificate(matchingCert)
            val subjectDN = cert.subjectDN.name
            val serialNumber = cert.serialNumber.toString()
            val issuerDN = cert.issuerDN.name

            Log.d(TAG, "Signed by: $subjectDN")
            Log.d(TAG, "Serial Number: $serialNumber")
            Log.d(TAG, "Issuer: $issuerDN")
            val verifier = JcaSimpleSignerInfoVerifierBuilder()
                .build(cert)

            if (signer.verify(verifier)) {
                return true
            }
        }
        
        return false
        
    } catch (e: Exception) {
        Log.e(TAG, "Verification error: ${e.message}", e)
        return false
    }
}
    private fun signWithJKS(
        fileBytes: ByteArray,
        keystorePath: String,
        password: String,
        alias: String
    ): Map<String, String> {
        
        Log.d(TAG, "Starting JKS signing process")
        Log.d(TAG, "Keystore path: $keystorePath")
        Log.d(TAG, "Alias: $alias")
        
        val keystore = try {
            // First try JKS
            KeyStore.getInstance("JKS", "BC")

        } catch (e: Exception) {
            try {
                // If JKS fails, try PKCS12
                Log.w(TAG, "JKS not available, trying PKCS12")
                KeyStore.getInstance("PKCS12")
            } catch (e2: Exception) {
                try {
                    // If PKCS12 fails, try BKS (BouncyCastle KeyStore)
                    Log.w(TAG, "PKCS12 not available, trying BKS")
                    KeyStore.getInstance("BKS")
                } catch (e3: Exception) {
                    // Last resort - use default
                    Log.w(TAG, "Using default keystore type")
                    KeyStore.getInstance(KeyStore.getDefaultType())
                }
            }
        }
        
        val keystoreFile = try {
            FileInputStream(keystorePath)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to open keystore file: ${e.message}")
            throw Exception("Cannot open keystore file: ${e.message}")
        }
        
        try {
            keystore.load(keystoreFile, password.toCharArray())
            Log.d(TAG, "Keystore loaded successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to load keystore: ${e.message}")
            throw Exception("Invalid keystore or password: ${e.message}")
        } finally {
            keystoreFile.close()
        }
        
        if (!keystore.containsAlias(alias)) {
            Log.e(TAG, "Alias '$alias' not found in keystore")
            val aliases = keystore.aliases().toList()
            Log.d(TAG, "Available aliases: $aliases")
            throw Exception("Alias '$alias' not found. Available aliases: $aliases")
        }
        
        val privateKey = try {
            keystore.getKey(alias, password.toCharArray()) as PrivateKey
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get private key: ${e.message}")
            throw Exception("Cannot get private key: ${e.message}")
        }
        
        val certificate = try {
            keystore.getCertificate(alias) as X509Certificate
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get certificate: ${e.message}")
            throw Exception("Cannot get certificate: ${e.message}")
        }
        
        val publicKey = certificate.publicKey
        Log.d(TAG, "Private key algorithm: ${privateKey.algorithm}")
        Log.d(TAG, "Certificate subject: ${certificate.subjectDN}")
        
        val messageDigest = MessageDigest.getInstance("SHA-256")
        val hash = messageDigest.digest(fileBytes)
        
        val signatureAlgorithm = when (privateKey.algorithm) {
            "RSA" -> "SHA256withRSA"
            "DSA" -> "SHA256withDSA"
            "EC" -> "SHA256withECDSA"
            else -> {
                Log.w(TAG, "Unknown key algorithm: ${privateKey.algorithm}, using SHA256withRSA")
                "SHA256withRSA"
            }
        }
        
        val signature = Signature.getInstance(signatureAlgorithm)
        signature.initSign(privateKey)
        signature.update(hash)
        val signatureBytes = signature.sign()
      
       val certList = listOf(certificate)
val certStore = JcaCertStore(certList)

val contentSigner = JcaContentSignerBuilder(signatureAlgorithm).build(privateKey)
val signerInfoGenerator = JcaSignerInfoGeneratorBuilder(
    JcaDigestCalculatorProviderBuilder().build()
).build(contentSigner, certificate)

val cmsGenerator = CMSSignedDataGenerator()
cmsGenerator.addSignerInfoGenerator(signerInfoGenerator)
cmsGenerator.addCertificates(certStore)

val dataToSign = CMSProcessableByteArray(fileBytes)
val signedData = cmsGenerator.generate(dataToSign, false) // false = detached

val p7sFile = File(cacheDir, "$alias.p7s")
val fileName = "$alias.p7s"
val mimeType = "application/pkcs7-signature"

val contentValues = ContentValues().apply {
    put(MediaStore.Downloads.DISPLAY_NAME, fileName)
    put(MediaStore.Downloads.MIME_TYPE, mimeType)
    put(MediaStore.Downloads.IS_PENDING, 1)
}

val resolver = context.contentResolver
val collection = MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
val fileUri = resolver.insert(collection, contentValues) ?: throw IOException("Failed to create file")

resolver.openOutputStream(fileUri).use { outputStream ->
    outputStream?.write(signedData.encoded)
}

contentValues.clear()
contentValues.put(MediaStore.Downloads.IS_PENDING, 0)
resolver.update(fileUri, contentValues, null, null)


Log.d(TAG, "File saved to Downloads: $fileUri")

FileOutputStream(p7sFile).use { it.write(signedData.encoded) }

Log.d(TAG, "Detached PKCS7 signature saved at: ${p7sFile.absolutePath}")

return mapOf(
    "p7sPath" to p7sFile.absolutePath,
    "algorithm" to signatureAlgorithm,
    "certificate" to Base64.encodeToString(certificate.encoded, Base64.NO_WRAP)
)
    }
}