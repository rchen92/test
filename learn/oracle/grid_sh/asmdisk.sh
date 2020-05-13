source ~/.bash_profile
asmcmd lsdg | awk '{if (NR==1) print "State Total_MB Free_MB Name Free_ratio" ;else printf("%s %d %d %s %0.f \n",$1,$7,$8,$NF,$8/$7*100)}'
