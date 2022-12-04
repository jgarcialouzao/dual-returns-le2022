program define censoredtobit_CHK, byable(recall)
                    
marksample use
		
			cnreg logdailywages age oneobs meanw_noT meantop_noT parttime sector_* provfirm_* fage_* month_* if `use', censored(cens)

			predict xb,  xb        
			gen se=_b[/sigma]      
			replace mu=xb          if `use'
			replace sigma=se       if `use'
			drop xb se
						                    
            end
