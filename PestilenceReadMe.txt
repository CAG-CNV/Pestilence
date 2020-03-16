WHAT IS IT?
-----------
This program models the spread of an infectious disease.


HOW IT WORKS
------------
Organisms move randomly about. Travelers are meant to move more than meanderers. Move_Factor allows the user to select how many times farther travelers move than meanderers. When a healthy organism moves onto a patch within Infection_Radius patches of another organism that is infected there is a certain chance that it will also become infected ("Contact_Infection"). Various backgrounds provide the effect of natural boundaries between populations.

HOW TO USE IT
-------------
Click 'Setup' to display the chosen Background.
Click 'Place Populations' and click on the screen to be prompted about the 			characteristics of that population to create. This is not necessary when 		working with maps because the relative populations are already set up based off 	People_Map.
	-Characteristics prompted are:
	Travelers: The number of triangle shapes present.
	Meanderers: The number of circle shapes present.
	Percent_Infected: The percent of organisms that are infected.
	Density: The density that organisms will start.
Click 'Place Sources' and click the screen to enter characteristics of an infectious 		source to occur during the simulation. The source will fade away according to 		the value of Residue-yr.
	-Characteristics prompted are:
	Source_Delay: Which year the source will occur.
	Source_Intensity: The number of particles radiating from the epicenter.
	Source_Size: The radius of the source from its center.
Click 'Go' to begin the simulation.
Click 'Stop' to halt execution. 'Go' may be clicked again without data loss.
Click 'Clear People' to remove all people from the background. This also sets all 		variables to zero, including the time. This is useful because all populations 		and sources set will reoccur with desired changes.

Initial Conditions
Background: The boundary setup. The increasing number loosely represents a more 		    restrictive boundary.
Contact_Resistance: The number of infection opportunities escaped to produce 				    Max_Resistance. The individual builds up a percentage of resistance 		    after each opportunity until it reaches Max_Resistance after 			    the number of contacts is reached.
Max_Resistance: The optimal resistance obtained through evolutionary forces alleviating 		the threat to those exposed but not infected. Note that resistance is 			the opposite of Contact_Infection. So Contact_Infection is lowered 			it equals (100 - Max_Resistance) in individuals exposed 				Contact_Resistance times without being infected (Resistant).
%_Carriers: The percentage of people that become carriers of the disease rather than 		    infected. They can transmit the disease as if they were infected and live 		    75% of the Healthy Lifespan.
People_Map: The number of people that will represent the actual number of people on a 		    map. A percentage of this number is placed in a country depending on its 		    actual population percentage of the featured land mass.
Susceptible_Infection_Lifespan: The number of years before the organism dies once 					infected during the susceptible period (Above/Below).
Susceptible_Below: The age below which organisms are more susceptible to 				   the disease.  
Susceptible_Above: The age above which organisms are more susceptible to the disease.
Percent_Recovery: The percent chance that an infected organism will become healthy. 
Recover_Immune_Time: The time an organism is immune to the disease after recovery.
Infection_Lifespan: The number of years before the organism dies once infected. If its 			    age exceeds the Healthy_Lifespan it will die regardless.
Deadly_Mutations: The percent chance that an infected organism will experience a deadly 	          mutation that will take ten years off its life.
_ _Fertility: The percent chance that an organism will successfully reproduce given the 	      chance. If an infected organism breeds with a healthy one, the fertility 		      of each are multiplied together to produce an overall probability.
Procreation_Age: The age at which an organism can reproduce. (marked by a change to a 			 lighter color)
Healthy_Birth_Number: The number of offspring per procreation event. (assuming both 		              partners are healthy) 
Infected_Birth_Number: The number of offspring per procreation event. (assuming both 		               partners are infected) There is a 50% chance that the 				       Infected_Birth_Number will be produced in the case of a   			       healthy/infected reproduction.
Healthy_Lifespan: The number of years (Time) an organism will live assuming it is 			  healthy (blue). 
Carrying_Capacity: If this number of organisms is met in a radius of five (pixels), no 		           reproduction will take place.
Meanderer_Moves: How many "steps" meanderers take during the period of a year. 	                         (relative to pixel size)
Traveler_Moves: How many "steps" travelers take during the period of a year. 	
Infected_Moves: The amount of moves an infected individual loses each year.       
Contact_Infection: The percent chance that a healthy organism will be infected if it 			   comes in contact with an infected organism.
Infection_Radius: The radius that an infected organism must be in of a healthy organism 		  to infect it. Notice that contact infection plays a role.
Vac_Delay: The number of years after the emergence of the disease agent until a 		   successful vaccine is developed. A syringe appears at the bottom right 		   corner of the screen to indicate when the vaccine is available.
Vac_Stock: The percentage of people that have access to a vaccine once it is available.
Vac_Use: The percentage of the population that receives a vaccine when it is 			   available. Recipients of the vaccine are immune to the disease.
Vac_Effect: The percentage of vaccine users that become entirely immune to the disease.
PharmDelay: The number of years after the emergence of the disease agent until a 		     successful pharmaceutical drug is developed. A pill appears at the bottom 		     right corner of the screen to indicate when the drug is available.
PharmStock: The percentage of people that have access to pharmaceuticals once they 		    become available.
PharmUse: The percentage of the population that purchases pharmaceuticals to treat 		     the spreading disease. Note that people who recover on their own via 		     Percent_Recovery will not purchase drugs.
PharmEffect: The percentage of pharmaceutical users that are cured by usage.
Poor: The percentage of the population too poor to afford vaccines or pharmaceuticals.
Residue-yr: The number of years source fall out or infected person residue lasts in the  	    environment before fading away.
File_Output: To output values to an excel spreadsheet.
Clear_File: Deletes previous information instead of appending to past results.
File_Time_Interval: The interval that values are sent to the file.
Note: To copy the graphs right-click and select Copy Image



THINGS TO NOTICE
----------------
One important thing to understand is that infections do not proliferate themselves exclusively by reproducing. Their main sustenance is preying upon healthy individuals. Keep in mind that even though the infection radius may increase, barriers will prevent those on the other side of an infected organism even though they may be in the radius. Also, deadly mutations and recovery occur at the time of infection so that it only happens once even though this would happen at random times but the effect is the same. The varying fertilities allow the inclusion of the observation that meanderers often procreate more than travelers and to realize its affect on disease propagation. 


THINGS TO TRY
-------------
Try different backgrounds while keeping everything else the same. Observe how the different variables lead to a rapid or steady spread of disease. Be sure to keep all the variables in mind because one extreme value can offset the effect of the others drastically. Try any combination and examine the different equilibriums or lack thereof. The graphs also reveal a lot about trends. You can even utilize the spreadsheet formatted output for further graphical analysis.


EXTENDING THE MODEL
-------------------
Most variables were included that could reasonably fit on the screen. 


NETLOGO FEATURES
----------------
The graphical tools allow an immediate analysis of trends. 

RELATED MODELS
--------------
Virus is a more basic model. The HIV model is also based on a similar idea.

CREDITS AND REFERENCES
----------------------
Produced by Joe Glessner (jglessner@usip.edu) under the direction of Dr. James Johnson 
University of the Sciences in Philadelphia
2004