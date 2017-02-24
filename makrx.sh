#!/bin/sh

######################################################################
#
# MAKRX.SH (only for WebAPI)
#  A XML Generator Which Makes From "XPath-value" Formatted Text
#
# === What is "XPath-value" Formatted Text? ===
# 1. Format
#    <XPath_string#1> + <0x20> + <value_at_that_path#1>
#    <XPath_string#2> + <0x20> + <value_at_that_path#2>
#    <XPath_string#3> + <0x20> + <value_at_that_path#3>
#             :              :              :
# 2. How do I get that formatted text?
#   "XPath-indexed value" also can be generated by "parsx.sh".
#   (Try to convert some XML data with parsrx.sh, and learn its format)
#
# === This Command will Do Like the Following Conversion ===
# 1. Input Text 
#    /foo/bar/@foo FOO
#    /foo/bar/@bar BAR
#    /foo/bar Wow!
#    /foo
# 2. Output Text This Command Generates
#    <?xml version="1.0" encoding="UTF-8"?>
#    <foo>
#      <bar bar="BAR" foo="FOO">Wow!</bar>
#    </foo>
#
# === Unsupported XML Format ===
#    EXAMPLE:
#       <A>aaaa<B>bbbb</B>ccccc</A>
#       ->can not handle "aaaa, ccccc"
#    This command can not handle cases 
#    where child tag and parent tag values exist in parallel.
#    But this is not a problem when using webAPI.
#
# === Usage ===
# Usage : makrx.sh [XPath-value_textfile]
#
#
# Written by BRAVEMAN LONGBRIDGE (@BRAVEMANLBRID) on 2017-02-24
#
# This is a public-domain software (CC0). It means that all of the
# people can use this for any purposes with no restrictions at all.
# By the way, I am fed up the side effects which are broght about by
# the major licenses.
#
######################################################################



######################################################################
# Initial configuration
######################################################################

# === Initialize shell environment ===================================
set -u
export LC_ALL=C
export PATH="$(command -p getconf PATH)${PATH:+:}${PATH:-}"

# === Usage printing function ========================================
print_usage_and_exit () {
  cat <<-USAGE 1>&2
	Usage   : ${0##*/} [XPath-value_textfile]
	Version : 2017-02-24 00:03:24 JST
	          (POSIX Bourne Shell/POSIX commands)
	USAGE
  exit 1
}


######################################################################
# Parse Arguments
######################################################################

# === Print the usage when "--help" is put ===========================
case "$# ${1:-}" in
  '1 -h'|'1 --help'|'1 --version') print_usage_and_exit;;
esac

# === Get the filepath ===============================================
file='-'
case "$#" in
  0) :
     ;;
  1) if [ -f "$1" ] || [ -c "$1" ] || [ -p "$1" ] || [ "_$1" = '_-' ]; then
       file=$1
     fi
     ;;
  *) print_usage_and_exit
     ;;
esac


######################################################################
# Main Routine (Convert and Generate)
######################################################################

# === Open the "XPath-value" data source =============================
cat "$file"                                                          | 
#                                                                    #
# === tagの属性値の/を一時的に^に変換 ================================
sed '/@/ s:@:\n@:'                                                   |
sed '/@/ s:/:^:g'                                                    |
sed '/@/ s:@\(.*\) \(.*\):@\1="\2":'                                 |
#                                                                    #
# === 余分な改行を元に戻す ===========================================
awk '/^\/.*\/$/{printf("%s",$1)}/.*[^\/]$/{print $0}'                |
#                                                                    #
# === 各要素までのPath列挙、ソートのため文末に\付加 ==================
awk -F '/' '{                                                        #
  i=1;                                                               #
  while (i <= NF-1 ) {                                               #
    for(j=1;j<i;j++) {                                               #
      printf("%s/",$j);                                              #
    }                                                                #
    printf("%s\\\n",$i);                                             #
    i++;                                                             #
  }                                                                  #
  print $0}'                                                         |
#                                                                    #
# === 重複した行を削除 & tagを閉じるための並び替え ===================
sort -u                                                              |
#                                                                    #
# === XPath-valueの箇所をkey-valueに変換 =============================
awk -F '/' '{print $NF}'                                             |
#                                                                    #
# === 空白を一つにまとめる ===========================================
sed 's/  */ /g'                                                      |
#                                                                    #
# === xmlを生成する ==================================================
awk 'NF==2{printf("\n%s %s",$1, $2)}                                 #
     /^@/{printf(" %s",$0)}                                          #
     /\\$/{printf("\n%s",$0)}                                        #
     /^[^@]/ && /[^\\]$/ && NF<2{printf("\n%s",$0)}'                 |
sed 's/\(.*\) \([^@]*\) \(@.*\)$/<\1 \3>\2/'                         |
awk 'NF==2 && $0 !~ /@/{printf("<%s>%s</%s>\n",$1,$2,$1)}            #
     NF<2{print $0}NF>2{print $0}'                                   |
sed 's/ $//'                                                         |
sed '/^[^<].*[^\]$/ s/.*/<&>/'                                       |
grep -v '^\\$'                                                       |
grep -v '^$'                                                         |
sed '/.*\\$/ s:\(.*\)\\:</\1>:'                                      |
#                                                                    #
# === 余分なキャレットを/に戻す ======================================
sed 's:\^:/:g'                                                       |
#                                                                    #
# === @を除去 ========================================================
sed 's/@//g'                                                         |
#                                                                    #
# === 改行を除去 =====================================================
tr -d '\n'                                                           |
#                                                                    #
# === 先頭にxml version情報を付加 ====================================
sed 's/^/<?xml version="1.0" encoding="UTF-8"?>/'                    # 


