:- module form_urlencoded.

% Copyright (C) 2014 YesLogic Pty. Ltd.
% All rights reserved.

:- interface.

:- import_module assoc_list.

    % We assume that the current Mercury process uses UTF-8 string encoding,
    % and only allow UTF-8 keys and values!
    %
    % Returns keys in original order.
    %
:- pred parse_form_urlencoded(string::in, assoc_list(string, string)::out)
    is semidet.

%-----------------------------------------------------------------------------%
%-----------------------------------------------------------------------------%

:- implementation.

:- import_module char.
:- import_module int.
:- import_module list.
:- import_module pair.
:- import_module parsing_utils.
:- import_module string.
:- import_module unit.

% UNHANDLED YET
%
% http://www.w3.org/html/wg/drafts/html/master/forms.html#application/x-www-form-urlencoded-decoding-algorithm
%
% - if the first control of a form is 'text' and has name "isindex", the
% browser will send only the value for that control, probably without even an
% equals sign.
%
% - a hidden control named "_charset_" without a value will cause the browser
% to send the character encoding as a value, which is the character encoding by
% which to decode the names/values in the form.

%-----------------------------------------------------------------------------%

parse_form_urlencoded(Input, AssocList) :-
    promise_equivalent_solutions [ParseResult] (
        parsing_utils.parse(Input, no_skip_whitespace, all_pairs,
            ParseResult)
    ),
    ParseResult = ok(AssocList).

:- pred no_skip_whitespace(src::in, unit::out, ps::in, ps::out) is semidet.

no_skip_whitespace(_Src, unit, !PS) :-
    semidet_true.

:- pred all_pairs(src::in, assoc_list(string, string)::out,
    ps::in, ps::out) is semidet.

all_pairs(Src, AssocList, !PS) :-
    separated_list("&", pair, Src, AssocList, !PS),
    eof(Src, _, !PS).

:- pred pair(src::in, pair(string, string)::out,
    ps::in, ps::out) is semidet.

pair(Src, Name - Value, !PS) :-
    name(Src, Name, !PS),
    next_char(Src, '=', !PS),
    value(Src, Value, !PS).

:- pred name(src::in, string::out, ps::in, ps::out) is semidet.

name(Src, Decoded, !PS) :-
    one_or_more(octet, Src, Octets, !PS),
    string.from_code_unit_list(Octets, Decoded).

:- pred value(src::in, string::out, ps::in, ps::out) is semidet.

value(Src, Decoded, !PS) :-
    zero_or_more(octet, Src, Octets, !PS),
    string.from_code_unit_list(Octets, Decoded).

:- pred octet(src::in, int::out, ps::in, ps::out) is semidet.

octet(Src, Octet, !PS) :-
    next_char(Src, C, !PS),
    ( C = ('%') ->
        hex_octet(Src, Octet, !PS)
    ; C = ('+') ->
        char.to_int(' ', Octet)
    ;
        C \= ('='),
        C \= ('&'),
        char.to_int(C, Octet)
    ).

:- pred hex_octet(src::in, int::out, ps::in, ps::out) is semidet.

hex_octet(Src, Octet, !PS) :-
    next_char(Src, Hi, !PS),
    next_char(Src, Lo, !PS),
    hex_digit(Int_Hi, Hi),
    hex_digit(Int_Lo, Lo),
    Octet = (Int_Hi << 4) \/ Int_Lo.

:- pred hex_digit(int::out, char::in) is semidet.

hex_digit(0, '0').
hex_digit(1, '1').
hex_digit(2, '2').
hex_digit(3, '3').
hex_digit(4, '4').
hex_digit(5, '5').
hex_digit(6, '6').
hex_digit(7, '7').
hex_digit(8, '8').
hex_digit(9, '9').
hex_digit(10, 'A').
hex_digit(10, 'a').
hex_digit(11, 'B').
hex_digit(11, 'b').
hex_digit(12, 'C').
hex_digit(12, 'c').
hex_digit(13, 'D').
hex_digit(13, 'd').
hex_digit(14, 'E').
hex_digit(14, 'e').
hex_digit(15, 'F').
hex_digit(15, 'f').

%-----------------------------------------------------------------------------%
% vim: ft=mercury ts=4 sts=4 sw=4 et
