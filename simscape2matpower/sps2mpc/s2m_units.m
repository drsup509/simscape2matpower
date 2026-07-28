function f = s2m_units(u)
%S2M_UNITS  Multiplicative factor converting a value in unit string "u"
%   to SI base units (Ohm, H, F, S for per-length quantities expressed per
%   metre; metres for lengths). Simscape Electrical Three-Phase blocks report
%   distributed line parameters as e.g. 'Ohm/km', 'mH/km', 'uF/km'.
%
%   Examples:
%     s2m_units('Ohm/km') -> 1e-3   (Ohm/m)
%     s2m_units('mH/km')  -> 1e-6   (H/m)
%     s2m_units('uF/km')  -> 1e-9   (F/m)
%     s2m_units('km')     -> 1e3    (m)
%
%   Unknown units default to 1 with a warning.

u = strtrim(char(u));
switch u
    % --- lengths -> metres ---
    case 'km',      f = 1e3;
    case 'm',       f = 1;

    % --- resistance per length -> Ohm/m ---
    case {'Ohm/m'},  f = 1;
    case 'kOhm/km',  f = 1;      % 1e3 / 1e3
    case 'Ohm/km',   f = 1e-3;
    case 'mOhm/km',  f = 1e-6;

    % --- inductance per length -> H/m ---
    case 'H/m',   f = 1;
    case 'H/km',  f = 1e-3;
    case 'mH/km', f = 1e-6;
    case 'uH/km', f = 1e-9;

    % --- capacitance per length -> F/m ---
    case 'F/m',   f = 1;
    case 'F/km',  f = 1e-3;
    case 'mF/km', f = 1e-6;
    case 'uF/km', f = 1e-9;
    case 'nF/km', f = 1e-12;

    % --- power -> base W / VA ---
    case {'MW','MVA','MVAr','Mvar','MVAR'}, f = 1e6;
    case {'kW','kVA','kVAr','kvar','kVAR'}, f = 1e3;

    % --- dimensionless / scalar base units ---
    case {'V','kV','V*A','VA','W','var','A','Ohm','H','F','S','Hz','pu',''}
        % kV handled specially by callers that need it; treat as 1 here
        if strcmp(u,'kV'), f = 1e3; else, f = 1; end

    otherwise
        warning('s2m_units:unknown', ...
            'Unknown unit "%s"; assuming factor 1.', u);
        f = 1;
end
end
