# Headers
HEADER1 = "Carefully read the following law enforcement narrative:"

# Body Text

# this is just a copy-and-paste from the requirements
BODY1 = """
INSTRUCTIONS:
    Closely follow these instructions:
        - For each variable below return a 0 for 'no' and a 1 for 'yes' unless otherwise stated.
        - If more than two answers are available, return ONE of the numbered values.
        - Rely ONLY on information available in the narrative. Do NOT extrapolate.
        - Return a properly formatted json object where the keys are the variables and the values are the numeric labels.
        - Do NOT return anything other than the label. Do NOT include any discussion or commentary.

VARIABLES:   
    DepressedMood: The person was perceived to be depressed at the time
    MentalIllnessTreatmentCurrnt: Currently in treatment for a mental health or substance abuse problem
    HistoryMentalIllnessTreatmnt: History of ever being treated for a mental health or substance abuse problem
    SuicideAttemptHistory: History of attempting suicide previously
    SuicideThoughtHistory: History of suicidal thoughts or plans
    SubstanceAbuseProblem: The person struggled with a substance abuse problem. This combines AlcoholProblem and SubstanceAbuseOther from the coding manual
    MentalHealthProblem: The person had a mental health condition at the time
    DiagnosisAnxiety: The person had a medical diagnosis of anxiety
    DiagnosisDepressionDysthymia: The person had a medical diagnosis of depression
    DiagnosisBipolar: The person had a medical diagnosis of bipolar
    DiagnosisAdhd: The person had a medical diagnosis of ADHD
    IntimatePartnerProblem: Problems with a current or former intimate partner appear to have contributed
    FamilyRelationship: Relationship problems with a family member (other than an intimate partner) appear to have contributed
    Argument: An argument or conflict appears to have contributed
    SchoolProblem: Problems at or related to school appear to have contributed
    RecentCriminalLegalProblem: Criminal legal problem(s) appear to have contributed
    SuicideNote: The person left a suicide note
    SuicideIntentDisclosed: The person disclosed their thoughts and/or plans to die by suicide to someone else within the last month
    DisclosedToIntimatePartner: Intent was disclosed to a previous or current intimate partner
    DisclosedToOtherFamilyMember: Intent was disclosed to another family member
    DisclosedToFriend: Intent was disclosed to a friend
    InjuryLocationType: The type of place where the suicide took place.
        - 1: House, apartment
        - 2: Motor vehicle (excluding school bus and public transportation)
        - 3: Natural area (e.g., field, river, beaches, woods)
        - 4: Park, playground, public use area
        - 5: Street/road, sidewalk, alley
        - 6: Other
    WeaponType1: Type of weapon used 
        - 1: Blunt instrument
        - 2: Drowning
        - 3: Fall
        - 4: Fire or burns
        - 5: Firearm
        - 6: Hanging, strangulation, suffocation
        - 7: Motor vehicle including buses, motorcycles
        - 8: Other transport vehicle, eg, trains, planes, boats
        - 9: Poisoning
        - 10: Sharp instrument
        - 11: Other (e.g. taser, electrocution, nail gun)
        - 12: Unknown
"""


# add variable descriptions to variables
BODY2 = """
INSTRUCTIONS:
    Closely follow these instructions:
        - For each variable below return a 0 for 'no' and a 1 for 'yes' unless otherwise stated.
        - If more than two answers are available, return ONE of the numbered values.
        - Rely ONLY on information available in the narrative. Do NOT extrapolate.
        - Return a properly formatted json object where the keys are the variables and the values are the numeric labels.
        - Do NOT return anything other than the label. Do NOT include any discussion or commentary.

VARIABLES:   
    DepressedMood: The person was perceived to be depressed at the time
    - 1: Specific signs of depression were noted in the narrative (e.g., sad, withdrawn, hopeless)
    - 0: No mention of depressive symptoms

    MentalIllnessTreatmentCurrnt: Currently in treatment for a mental health or substance abuse problem
    - 1: The person was undergoing treatment for a mental health issue at the time of the incident
    - 0: No indication of current treatment

    HistoryMentalIllnessTreatmnt: History of ever being treated for a mental health or substance abuse problem
    - 1: Documentation of previous treatment for mental health or substance abuse is noted in the narrative
    - 0: No prior treatment mentioned

    SuicideAttemptHistory: History of attempting suicide previously
    - 1: A past suicide attempt was mentioned
    - 0: No documented prior attempts

    SuicideThoughtHistory: History of suicidal thoughts or plans
    - 1: Person's prior thoughts or plans of suicide were noted in the narrative
    - 0: No history of suicidal ideation mentioned

    SubstanceAbuseProblem: The person struggled with a substance abuse problem.
    - 1: Person was noted to have issues with alcohol or drug abuse
    - 0: No indication of substance abuse problems

    MentalHealthProblem: The person had a mental health condition at the time
    - 1: Person was noted to have a mental health condition at the time of the event
    - 0: No documented mental health condition

    DiagnosisAnxiety: The person had a medical diagnosis of anxiety
    - 1: Person was currently, or previously, been diagnosed or treated for anxiety
    - 0: No documented diagnosis or treatment for anxiety

    DiagnosisDepressionDysthymia: The person had a medical diagnosis of depression
    - 1: Person was currently, or previously, been diagnosed or treated for depression or dysthymia
    - 0: No documented diagnosis or treatment for depression

    DiagnosisBipolar: The person had a medical diagnosis of bipolar
    - 1: Person was currently, or previously, been diagnosed or treated for bipolar disorder
    - 0: No documented diagnosis or treatment for bipolar disorder

    DiagnosisAdhd: The person had a medical diagnosis of ADHD
    - 1: Person was documented as having been diagnosed or treated for ADHD
    - 0: Person had no documentation of treatment or diagnosis for ADHD

    IntimatePartnerProblem: Problems with a current or former intimate partner appear to have contributed
    - 1: Person's relationship issues with a spouse, partner, or ex-partner were mentioned as contributing factors
    - 0: No relationship issues were mentioned

    FamilyRelationship: Relationship problems with a family member (other than an intimate partner) appear to have contributed
    - 1: Person's conflicts with parents, siblings, children, or other family members contributed
    - 0: No family relationship problems mentioned

    Argument: An argument or conflict appears to have contributed
    - 1: A dispute, disagreement, or verbal altercation was mentioned as a contributing factor
    - 0: No argument or conflict mentioned

    SchoolProblem: Problems at or related to school appear to have contributed
    - 1: Issues such as academic struggles, bullying, or school disciplinary actions were noted
    - 0: No school-related problems mentioned

    RecentCriminalLegalProblem: Criminal legal problem(s) appear to have contributed
    - 1: The person was facing legal troubles such as arrest, charges, or sentencing
    - 0: No criminal legal issues mentioned

    SuicideNote: The person left a suicide note
    - 1: A written, digital, or verbal message was documented as a suicide note
    - 0: No mention of a suicide note

    SuicideIntentDisclosed: The person disclosed their thoughts and/or plans to die by suicide to someone else within the last month
    - 1: Suicide intent was communicated to another person within the last month
    - 0: No disclosure of intent mentioned

    DisclosedToIntimatePartner: Intent was disclosed to a previous or current intimate partner
    - 1: The person told a spouse or romantic partner about suicidal thoughts/plans
    - 0: No disclosure to an intimate partner

    DisclosedToOtherFamilyMember: Intent was disclosed to another family member
    - 1: The person told a parent, sibling, child, or other relative about suicidal thoughts/plans
    - 0: No disclosure to a family member

    DisclosedToFriend: Intent was disclosed to a friend
    - 1: The person told a friend about suicidal thoughts/plans
    - 0: No disclosure to a friend

    InjuryLocationType: The type of place where the suicide took place.
        - 1: House, apartment
        - 2: Motor vehicle (excluding school bus and public transportation)
        - 3: Natural area (e.g., field, river, beaches, woods)
        - 4: Park, playground, public use area
        - 5: Street/road, sidewalk, alley
        - 6: Other

    WeaponType1: Type of weapon used 
        - 1: Blunt instrument
        - 2: Drowning
        - 3: Fall
        - 4: Fire or burns
        - 5: Firearm
        - 6: Hanging, strangulation, suffocation
        - 7: Motor vehicle including buses, motorcycles
        - 8: Other transport vehicle, eg, trains, planes, boats
        - 9: Poisoning
        - 10: Sharp instrument
        - 11: Other (e.g. taser, electrocution, nail gun)
        - 12: Unknown
"""


# Example Output
EXAMPLE_OUTPUT1 = """
EXAMPLE OUTPUT:
{
    "DepressedMood": 1,
    "MentalIllnessTreatmentCurrnt": 0,
    "HistoryMentalIllnessTreatmnt": 0,
    "SuicideAttemptHistory": 0,
    "SuicideThoughtHistory": 0,
    "SubstanceAbuseProblem": 1,
    "MentalHealthProblem": 0,
    "DiagnosisAnxiety": 0,
    "DiagnosisDepressionDysthymia": 0,
    "DiagnosisBipolar": 0,
    "DiagnosisAdhd": 1,
    "IntimatePartnerProblem": 0,
    "FamilyRelationship": 0,
    "Argument": 1,
    "SchoolProblem": 1,
    "RecentCriminalLegalProblem": 0,
    "SuicideNote": 1,
    "SuicideIntentDisclosed": 0,
    "DisclosedToIntimatePartner": 0,
    "DisclosedToOtherFamilyMember": 0,
    "DisclosedToFriend": 0,
    "InjuryLocationType": 1,
    "WeaponType1": 5
}
"""

# few shot examples
EXAMPLE_OUTPUT2 = """
Here is an example narrative and expected output:

EXAMPLE NARRATIVE 1:
The V was a XX XX XX XX who died of an intentional mixed drug (fentanyl, sertraline, and amphetamine) intoxication. The V had been court ordered to admit to a addiction recovery center, and he was admitted two days ago.  He was last seen alive yesterday during room checks. He was in his room with two others. The V was found this morning unresponsive and CPR was instituted. EMS arrived and confirmed death. The V had a significant past medical history of anxiety, depression, cleft palate repair, PTSD and asthma. He reportedly had been very depressed lately and had expressed suicidal ideations including that he was going to "take lots of pills." Per grandmother and mother, the V was known to take Percocet and Adderall.

EXAMPLE OUTPUT 1:
{
    "DepressedMood": 1,
    "MentalIllnessTreatmentCurrnt": 1,
    "HistoryMentalIllnessTreatmnt": 1,
    "SuicideAttemptHistory": 0,
    "SuicideThoughtHistory": 1,
    "SubstanceAbuseProblem": 1,
    "MentalHealthProblem": 1,
    "DiagnosisAnxiety": 1,
    "DiagnosisDepressionDysthymia": 1,
    "DiagnosisBipolar": 0,
    "DiagnosisAdhd": 0,
    "IntimatePartnerProblem": 0,
    "FamilyRelationship": 0,
    "Argument": 0,
    "SchoolProblem": 0,
    "RecentCriminalLegalProblem": 1,
    "SuicideNote": 0,
    "SuicideIntentDisclosed": 1,
    "DisclosedToIntimatePartner": 0,
    "DisclosedToOtherFamilyMember": 0,
    "DisclosedToFriend": 0,
    "InjuryLocationType": 6,
    "WeaponType1": 9
}

Here is another example narrative and expected output:

EXAMPLE NARRATIVE 2:
Victim XX died of a self-intentional gunshot wound to the head, resulting in an exit wound, with a .357 caliber revolver at the victim's place of residence. The victim's ex-wife had attempted to contact the victim and had told dispatchers the victim was depressed and had thoughts of suicide. The victim left a suicide for his parents and ex-wife. Per the ex-wife, he was extremely depressed and the last text she received from him was telling her goodbye. The victim had never gotten over their divorce and struggled with depression and alcohol abuse. EMS was present and confirmed the victim deceased.

EXAMPLE OUTPUT 2:
{
    "DepressedMood": 1,
    "MentalIllnessTreatmentCurrnt": 0,
    "HistoryMentalIllnessTreatmnt": 0,
    "SuicideAttemptHistory": 1,
    "SuicideThoughtHistory": 0,
    "SubstanceAbuseProblem": 1,
    "MentalHealthProblem": 0,
    "DiagnosisAnxiety": 0,
    "DiagnosisDepressionDysthymia": 0,
    "DiagnosisBipolar": 0,
    "DiagnosisAdhd": 0,
    "IntimatePartnerProblem": 1,
    "FamilyRelationship": 0,
    "Argument": 0,
    "SchoolProblem": 0,
    "RecentCriminalLegalProblem": 0,
    "SuicideNote": 1,
    "SuicideIntentDisclosed": 1,
    "DisclosedToIntimatePartner": 1,
    "DisclosedToOtherFamilyMember": 0,
    "DisclosedToFriend": 0,
    "InjuryLocationType": 1,
    "WeaponType1": 5
}

Here is another example narrative and expected output:

EXAMPLE NARRATIVE 3:
This is the death of a XX XX (V). LE was dispatched at 0806 hours in reference to the V who was shot in the head. Upon arrival, the V was in an apartment with 2 other women present and a firearm. The V had a gunshot wound to the right side of the head and no exit was noted. Medics arrived and took over life saving efforts. Per the V's fiance the V suffered form anxiety and depression. The V's mood had been changing all day as he was approaching the 1 year marker of his high school friend dying by suicide. The V had been drinking throughout the day and at 2000 hours hours the V went to the park. The V was not allowed to have firearms. Prior to shooting himself the V said "you don't think I'll do it." The V was transported to the hospital where he died. The firearm used was .22 caliber and a note was found that appeared to have been written by a child that read "I love mom and dad." There were several gummy bears rolled up in a plastic bag with #9 written on it and a small zip lock bag with pink powder inside. There were several bottles of alcohol, THC oil and cigarette butts in the bathroom. Last year the V was committed for treatment of mental disorder.

EXAMPLE OUTPUT 3:
{
    "DepressedMood": 0,
    "MentalIllnessTreatmentCurrnt": 0,
    "HistoryMentalIllnessTreatmnt": 1,
    "SuicideAttemptHistory": 0,
    "SuicideThoughtHistory": 1,
    "SubstanceAbuseProblem": 1,
    "MentalHealthProblem": 1,
    "DiagnosisAnxiety": 1,
    "DiagnosisDepressionDysthymia": 1,
    "DiagnosisBipolar": 0,
    "DiagnosisAdhd": 0,
    "IntimatePartnerProblem": 0,
    "FamilyRelationship": 0,
    "Argument": 0,
    "SchoolProblem": 0,
    "RecentCriminalLegalProblem": 0,
    "SuicideNote": 1,
    "SuicideIntentDisclosed": 1,
    "DisclosedToIntimatePartner": 1,
    "DisclosedToOtherFamilyMember": 0,
    "DisclosedToFriend": 0,
    "InjuryLocationType": 1,
    "WeaponType1": 5 
}

"""