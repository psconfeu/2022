# use this function if you do not want to test NTLM hashes but 
# would like to test plain-text passwords
# the function turns plain text into NTLM hashes for you:

function Get-Md4Hash
{
  param
  (
    [Parameter(Mandatory,ValueFromPipeline)]      
    [SecureString]
    $Text
  )

  begin
  {   
    # access Windows bcrypt.dll API: 
    Add-Type -TypeDefinition @'
        using System;
        using System.Text;
        using System.Runtime.InteropServices;
        public class CryptoHelper
        {
            [DllImport("bcrypt.dll", CharSet = CharSet.Auto)]
            public static extern NTStatus BCryptOpenAlgorithmProvider(
                [Out] out IntPtr phAlgorithm,
                [In] string pszAlgId,
                [In, Optional] string pszImplementation,
                [In] UInt32 dwFlags);
 
            [DllImport("bcrypt.dll")]
            public static extern NTStatus BCryptCloseAlgorithmProvider(
                [In, Out] IntPtr hAlgorithm,
                [In] UInt32 dwFlags);
 
            [DllImport("bcrypt.dll", CharSet = CharSet.Auto)]
            public static extern NTStatus BCryptCreateHash(
                [In, Out] IntPtr hAlgorithm,
                [Out] out IntPtr phHash,
                [Out] IntPtr pbHashObject,
                [In, Optional] UInt32 cbHashObject,
                [In, Optional] IntPtr pbSecret,
                [In] UInt32 cbSecret,
                [In] UInt32 dwFlags);
 
            [DllImport("bcrypt.dll")]
            public static extern NTStatus BCryptDestroyHash(
                [In, Out] IntPtr hHash);
 
            [DllImport("bcrypt.dll")]
            public static extern NTStatus BCryptHashData(
                [In, Out] IntPtr hHash,
                [In, MarshalAs(UnmanagedType.LPArray)] byte[] pbInput,
                [In] int cbInput,
                [In] UInt32 dwFlags);
 
            [DllImport("bcrypt.dll")]
            public static extern NTStatus BCryptFinishHash(
                [In, Out] IntPtr hHash,
                [Out, MarshalAs(UnmanagedType.LPArray)] byte[] pbInput,
                [In] int cbInput,
                [In] UInt32 dwFlags);
 
            [Flags]
            public enum AlgOpsFlags : uint
            {           
                BCRYPT_PROV_DISPATCH = 0x00000001,
                BCRYPT_ALG_HANDLE_HMAC_FLAG = 0x00000008,
                BCRYPT_HASH_REUSABLE_FLAG = 0x00000020
            }
 
            public enum NTStatus : uint
            {
                STATUS_SUCCESS = 0x00000000
            }
        }
'@
 
    [Byte[]]$HashBytes   = [Byte[]]::new(16)
    [IntPtr]$PHAlgorithm = [IntPtr]::Zero
    [IntPtr]$PHHash      = [IntPtr]::Zero
        
    try
    {
      # Open Algorithm Provider:
      if ([CryptoHelper]::BCryptOpenAlgorithmProvider([Ref] $PHAlgorithm, 'MD4', $Null, 0) -ne 0)
      { throw 'FailedToOpen' }
      
    }
    catch
    {
      # did not work, close and bail out:
      if ($PHAlgorithm) { [void][CryptoHelper]::BCryptCloseAlgorithmProvider($PHAlgorithm, 0) }
      throw "Get-MD4Hash: Cannot open BCryptOpenAlgorithmProvider."
    }
  }

  process
  {
    # convert string to byte array:
    $PlainText = [PSCredential]::new('dummy', $Text).GetNetworkCredential().Password
    $DataToHash = [System.Text.Encoding]::Unicode.GetBytes($PlainText)

    # compute hash:
    $result = [CryptoHelper]::BCryptCreateHash($PHAlgorithm, [Ref] $PHHash, [IntPtr]::Zero, 0, [IntPtr]::Zero, 0, 0)
    if ($result -eq 0)
    { 
      $null = [CryptoHelper]::BCryptHashData($PHHash, $DataToHash, $DataToHash.Length, 0)
      $null = [CryptoHelper]::BCryptFinishHash($PHHash, $HashBytes, $HashBytes.Length, 0)
      $null = [CryptoHelper]::BCryptDestroyHash($PHHash)
      
      # convert bytes to hex string and remove delimiter and return:
      return [System.BitConverter]::ToString($HashBytes).Replace('-','')
    }
  }
  
  end
  {
    if ($PHAlgorithm) { $null=[CryptoHelper]::BCryptCloseAlgorithmProvider($PHAlgorithm,0) }
  }
}