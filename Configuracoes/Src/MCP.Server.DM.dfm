object MCPServerDM: TMCPServerDM
  Height = 480
  Width = 640
  object TMSMCPServer1: TTMSMCPServer
    Tools = <
      item
        Name = 'PingTest'
        Description = 'Recebe a string ping e retorna pong'
        Properties = <>
        OnExecute = TMSMCPServer1Tools0Execute
        ReturnType = ptString
        ReadOnlyHint = False
        DestructiveHint = False
        IdempotentHint = False
        OpenWorldHint = False
      end
      item
        Name = 'GerarNFe'
        Description = 'Gera uma NF-e com o n'#250'mero informado'
        Properties = <
          item
            Name = 'NumeroParaNFe'
            PropertyType = ptInteger
            Description = 'N'#250'mero para gera'#231#227'o da NFe'
          end>
        OnExecute = TMSMCPServer1Tools1Execute
        ReturnType = ptString
        ReadOnlyHint = False
        DestructiveHint = False
        IdempotentHint = False
        OpenWorldHint = False
      end>
    Resources = <>
    Prompts = <>
    ServerVersion = '1.0.0'
    ServerName = 'FileSystemMCPServer'
    Transport = TMSMCPStreamableHTTPTransport1
    OnLog = TMSMCPServer1Log
    Left = 208
    Top = 64
  end
  object TMSMCPStreamableHTTPTransport1: TTMSMCPStreamableHTTPTransport
    Port = 8080
    MCPEndpoint = '/acbrnfe'
    ProtocolVersion = '2025-06-18'
    UseSSL = False
    SSLVersion = sslvTLSv1_2
    Left = 376
    Top = 64
  end
end
