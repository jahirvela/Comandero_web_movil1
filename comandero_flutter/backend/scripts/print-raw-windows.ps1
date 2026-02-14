<#
.SYNOPSIS
  Envia datos RAW (ESC/POS) a una impresora por nombre en Windows.
  Usado por el backend para tickets termicos sin depender de paquetes nativos Node.
.PARAMETER PrinterName
  Nombre exacto de la impresora (ej. ZKTECO).
.PARAMETER FilePath
  Ruta del archivo con el contenido a imprimir (bytes ESC/POS).
.EXIT
  0 = exito, 1 = error (mensaje en stderr).
#>
param(
  [Parameter(Mandatory=$true)][string]$PrinterName,
  [Parameter(Mandatory=$true)][string]$FilePath
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $FilePath)) {
  Write-Error "Archivo no encontrado: $FilePath"
  exit 1
}

$rawBytes = [System.IO.File]::ReadAllBytes($FilePath)
if ($rawBytes.Length -eq 0) {
  Write-Error "El archivo esta vacio."
  exit 1
}

$code = @'
using System;
using System.Runtime.InteropServices;

public class RawPrinter {
  [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi)]
  public struct DOCINFOA {
    [MarshalAs(UnmanagedType.LPStr)] public string pDocName;
    [MarshalAs(UnmanagedType.LPStr)] public string pOutputFile;
    [MarshalAs(UnmanagedType.LPStr)] public string pDataType;
  }

  [DllImport("winspool.Drv", EntryPoint = "OpenPrinterA", SetLastError = true, CharSet = CharSet.Ansi, ExactSpelling = true)]
  public static extern bool OpenPrinter([MarshalAs(UnmanagedType.LPStr)] string pPrinterName, out IntPtr phPrinter, IntPtr pDefault);

  [DllImport("winspool.Drv", EntryPoint = "ClosePrinter", SetLastError = true)]
  public static extern bool ClosePrinter(IntPtr hPrinter);

  [DllImport("winspool.Drv", EntryPoint = "StartDocPrinterA", SetLastError = true, CharSet = CharSet.Ansi, ExactSpelling = true)]
  public static extern bool StartDocPrinter(IntPtr hPrinter, int level, ref DOCINFOA pDocInfo);

  [DllImport("winspool.Drv", EntryPoint = "EndDocPrinter", SetLastError = true)]
  public static extern bool EndDocPrinter(IntPtr hPrinter);

  [DllImport("winspool.Drv", EntryPoint = "StartPagePrinter", SetLastError = true)]
  public static extern bool StartPagePrinter(IntPtr hPrinter);

  [DllImport("winspool.Drv", EntryPoint = "EndPagePrinter", SetLastError = true)]
  public static extern bool EndPagePrinter(IntPtr hPrinter);

  [DllImport("winspool.Drv", EntryPoint = "WritePrinter", SetLastError = true)]
  public static extern bool WritePrinter(IntPtr hPrinter, IntPtr pBytes, int dwCount, out int dwWritten);

  public static bool SendRaw(string printerName, byte[] data) {
    IntPtr hPrinter = IntPtr.Zero;
    try {
      if (!OpenPrinter(printerName, out hPrinter, IntPtr.Zero))
        return false;
      DOCINFOA di = new DOCINFOA();
      di.pDocName = "Ticket";
      di.pOutputFile = null;
      di.pDataType = "RAW";
      if (!StartDocPrinter(hPrinter, 1, ref di))
        return false;
      try {
        if (!StartPagePrinter(hPrinter))
          return false;
        try {
          IntPtr pUnmanaged = Marshal.AllocCoTaskMem(data.Length);
          try {
            Marshal.Copy(data, 0, pUnmanaged, data.Length);
            int written;
            if (!WritePrinter(hPrinter, pUnmanaged, data.Length, out written) || written != data.Length)
              return false;
          } finally {
            Marshal.FreeCoTaskMem(pUnmanaged);
          }
        } finally {
          EndPagePrinter(hPrinter);
        }
      } finally {
        EndDocPrinter(hPrinter);
      }
      return true;
    } finally {
      if (hPrinter != IntPtr.Zero)
        ClosePrinter(hPrinter);
    }
  }
}
'@

try {
  Add-Type -TypeDefinition $code -ErrorAction SilentlyContinue
} catch {
  if ($_.Exception.Message -notmatch 'already exists') { throw }
}

$ok = [RawPrinter]::SendRaw($PrinterName, $rawBytes)
if (-not $ok) {
  $err = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
  Write-Error "Error al enviar a impresora '$PrinterName' (codigo: $err). Verifica nombre y que este encendida."
  exit 1
}
exit 0
