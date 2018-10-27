REM Please set the swich SW19 as 'AS Mode'.
pause
%QUARTUS_ROOTDIR%\\bin\\quartus_pgm.exe -m AS -c 1 -o "p;de2i_150_qsys_pcie.pof"
REM Please resotre the swich SW19 to 'Run Mode'.
pause