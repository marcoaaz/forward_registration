
function [name_full, name_element] = search_elements(sample_data4)

varNames = sample_data4.Properties.VariableNames;

expression1 = '\w+\d+_ppm_mean';
expression2 = '(?<element>[a-zA-Z]+)\d+_ppm_mean';

a = regexp(varNames, expression1, 'match');
name_full = [a{:}]; %original col name

c = regexp(varNames, expression2, 'names');
d = [c{:}]; %element name
e = struct2table(d);
name_element = e.element;

end