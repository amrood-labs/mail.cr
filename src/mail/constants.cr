# encoding: us-ascii

module Mail
  module Constants
    white_space = %q|\x9\x20|
    qp_safe = %q|\x20-\x3c\x3e-\x7e|

    LAX_CRLF     = /\r?\n/
    WSP          = /[\x9\x20]/
    FWS          = /#{LAX_CRLF}#{WSP}*/
    UNFOLD_WS    = /#{LAX_CRLF}(#{WSP})/m
    TEXT         = /[\x1-\x8\xB\xC\xE-\x7f]/ # + obs-text
    FIELD_NAME   = /[\x21-\x39\x3b-\x7e]+/
    FIELD_PREFIX = /\A(#{FIELD_NAME})/
    FIELD_BODY   = /.+/m
    FIELD_LINE   = /^[\x21-\x39\x3b-\x7e]+:\s*.+$/
    FIELD_SPLIT  = /^(#{FIELD_NAME})\s*:\s*(#{FIELD_BODY})?$/
    HEADER_LINE  = /^([\x21-\x39\x3b-\x7e]+:\s*.+)$/
    HEADER_SPLIT = /#{LAX_CRLF}(?!#{WSP})/

    QP_UNSAFE    = /[^#{qp_safe}]/
    QP_SAFE      = /[#{qp_safe}]/
    CONTROL_CHAR = /[\x00-\x1f\x7f-\xff]/

    ATOM_UNSAFE        = /[\(\)\<\>\[\]\:;@\\\\,\.\"\x00-\x1f\x7f-\xff ]/
    PHRASE_UNSAFE      = /[\(\)\<\>\[\]\:;@\\\\,\.\"\x00-\x1f\x7f-\xff]/
    TOKEN_UNSAFE       = /[\(\)<>@,;:\\\\\"\/\[\]\?=\x00-\x1f\x7f-\xff ]/
    ENCODED_VALUE      = /\=\?([^?]+)\?([QB])\?[^?]*?\?\=/mi
    FULL_ENCODED_VALUE = /(\=\?[^?]+\?[QB]\?[^?]*?\?\=)/mi

    EMPTY       = ""
    SPACE       = " "
    UNDERSCORE  = "_"
    HYPHEN      = "-"
    COLON       = ":"
    ASTERISK    = "*"
    CRLF        = "\r\n"
    CR          = "\r"
    LF          = "\n"
    CR_ENCODED  = "=0D"
    LF_ENCODED  = "=0A"
    CAPITAL_M   = "M"
    EQUAL_LF    = "=\n"
    NULL_SENDER = "<>"

    Q_VALUES = ["Q", "q"]
    B_VALUES = ["B", "b"]
  end
end
