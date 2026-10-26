truncate table public.ai_career_threat_index;

alter table ai_career_threat_index 
	alter column defense_skill_1 type varchar(255),
	alter column defense_skill_2 type varchar(255),
	alter column defense_skill_3 type varchar(255),
	alter column title type varchar(255),
	alter column category type varchar(100),
	alter column risk_level type varchar(50),
	alter column salary_trend type varchar(50);

select * 
from ai_career_threat_index
limit 10;

-- No duplicates
select slug, count(*) as duplicates
from ai_career_threat_index
group by slug
having count(*) > 1;

-- 15 fields of work
select category
from ai_career_threat_index
group by category;

-- Education field has the lowest replacement risk level by AI
-- Administrative & Operations field has the highest replacement risk level by AI
select category, count(risk_level) as high_risk_level
from ai_career_threat_index
where risk_level = 'High' or risk_level = 'Very High'
group by category
order by high_risk_level;

-- In Education field only Tutoring is sensitive to AI adoption and agentic AI
-- AI can quikly explain concepts and help students to excersise everywhere and anytime
select *
from ai_career_threat_index
where risk_level = 'Very High' and category = 'Education'
or risk_level = 'High' and category = 'Education';

-- In Administrative & Operations field, there are many roles menaced by AI and agentic AI implementation
-- Data entry and Administrative assistant are the ones that have more probability to be replaced by AI
-- Administrative & Operations field has many repetitive activities where AI is known to be really good at
select *
from ai_career_threat_index
where risk_level = 'Very High' and category = 'Administrative & Operations'
or risk_level = 'High' and category = 'Administrative & Operations';

-- Roles with High or Very High replacement level by AI and agents
select *
from ai_career_threat_index
where risk_level = 'Very High' and agentic_risk = 'Very High'
or risk_level = 'High' and agentic_risk = 'High';

-- Creating table with average salary per role
create table salary_comparison_table as
with salary_comparison as(
select *, 
(salary_high_usd + salary_low_usd) / 2.0 as avg_salary
from ai_career_threat_index
)
select *
from salary_comparison;

select *
from salary_comparison_table
order by avg_salary desc;

-- Medium-high income roles are the most threatened by AI and agentic AI automation, followed by medium income roles
with salary_range as(
select *,
case when avg_salary <= 50000 then 'medium income'
when avg_salary <= 100000 then 'medium-high income'
when avg_salary <= 150000 then 'high income'
else 'very high income'
end as income_range
from salary_comparison_table
)
select income_range,
count(*) filter (where risk_level in ('High', 'Very High')) as risk_level_count,
count(*) filter (where agentic_risk in ('High', 'Very High')) as agentic_risk_count
from salary_range
group by income_range
order by min(avg_salary);

-- Job positions with a declining or mixed salary trend are related to a higher risk of AI replacement
select salary_trend,
count(*) filter (where risk_level in ('High', 'Very High')) as risk_level_count,
count(*) filter (where agentic_risk in ('High', 'Very High')) as agentic_risk_count,
count(title) as total_roles
from ai_career_threat_index
group by salary_trend;

-- Administrative, Legal, Marketing & Sales and Business & Finance fields have the highest point (60 and beyond) of AI and agentic AI automation 
select title,
category,
risk_level,
agentic_risk,
sub_task_automation
from ai_career_threat_index 
where (sub_task_automation > 60)
and (risk_level = 'High' or risk_level = 'Very High')
and (agentic_risk = 'High' or agentic_risk = 'Very High')
order by category, sub_task_automation desc;

-- Roles with high risk of AI and agentic AI substitution and declining salary trend 
-- Data entry clerk and Telemarketer have both a Very High risk level of AI and agentic AI implementation plus a declining salary trend
select title,
category,
risk_level,
agentic_risk,
salary_trend
from ai_career_threat_index
where (risk_level = 'High' or risk_level = 'Very High')
and (agentic_risk = 'High' or agentic_risk = 'Very High')
and salary_trend = 'declining'
order by category asc;

-- In quali ruoli la maturità degli strumenti AI e la loro adozione sono più alte?
-- Roles where AI tools and its adoption register more points (70 and beyond)
-- Marketing & Sales roles have the highest points for tool maturity and adoption
select title,
category,
sub_tool_maturity,
sub_adoption
from ai_career_threat_index
where sub_tool_maturity >= 70
and sub_adoption >= 70
order by category asc, sub_tool_maturity desc, sub_adoption desc;

-- AI increased its automation score points (where those are present) in every roles between 2025 and 2026
-- 2025 miss the second quarter of score points, therefore the operation is made with only first and third quarters
-- Less than a third of the roles in the dataset have a score risk associated
with score_points as(
select *,
(score_q1_2025 + score_q3_2025)/2.0 as score_mean_2025,
(score_q1_2026 + score_q2_2026 + score_q3_2026)/3.0 as score_mean_2026 
from ai_career_threat_index)
select title,
category,
score_mean_2025,
score_mean_2026, 
round(score_mean_2026 - score_mean_2025) as score_difference, 
round(((score_mean_2026 - score_mean_2025) / score_mean_2025) * 100.0) as score_increased_percentage
from score_points
order by score_increased_percentage asc;

-- Quali competenze di difesa ricorrono più spesso nei ruoli ad alto rischio?
-- The most frequent defense skills for high risk roles include job tasks specialization, cooperation with AI, improvement of human relations and agentic activities supervision 
select title,
category,
risk_level,
agentic_risk,
defense_skill_1,
defense_skill_2,
defense_skill_3
from ai_career_threat_index
where (risk_level = 'High' or risk_level = 'Very High') 
and (agentic_risk = 'High' or agentic_risk = 'Very High');

-- AI risk level in roles with same soc code 
-- Soc codes 13-1071, 13-1081, 27-3043 and 43-5071 show the largest diversity of risk level 
-- 13-1071: In HR & Recruiting field AI can automize talent research and acquisition, while mapping operations, analysis and business monitoring still need human intervention 
-- 13-1081: In Administrative & Operations field AI can help with track and direct the flow of goods, but analysis of supply chain is reserved to human analysts
-- 27-3043: In Marketing and Creative fields AI is very good at create marketing and informative contents, but natural creativity and the presence of rights that protect entertainment worker represent a defense against technology automation  
-- 43-5071: In Administrative and Trasportation fields computer vision algorithms can automatically register and track goods, but human component continue to be important for product checking and vendor coordination 
select title,
category,
soc_code,
risk_level,
insight
from ai_career_threat_index
where soc_code in (
select soc_code
from ai_career_threat_index
group by soc_code
having count(distinct risk_level) > 1
)
order by soc_code, risk_level;