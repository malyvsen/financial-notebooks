### A Pluto.jl notebook ###
# v0.12.17

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : missing
        el
    end
end

# ╔═╡ c27386f4-4393-11eb-1fb2-43bf6a1d7de0
begin
	using Distributions
	using Interpolations
	using Statistics
	using StatsBase
	using StatsPlots
	gr(fmt=:png) # forces sensible plot size
	using PlutoUI
	md"Imports"
end

# ╔═╡ 2c367f68-4394-11eb-1098-23e08449a7dd
md"# Oszczędzanie
Na celowniku: godna emerytura."

# ╔═╡ 12dca160-44a1-11eb-1950-b3a0b9f380a3
md"Jesteś $(@bind sex_pl Select([\"mężczyzną\", \"kobietą\"])) w wieku $(@bind current_age NumberField(0:100, default=20)) lat."

# ╔═╡ 0dda613c-4395-11eb-2c8e-ff08529d84e8
md"Planujesz przejść na emeryturę w wieku $(@bind age_at_retirement NumberField(0:100, default=65)) lat."

# ╔═╡ 5e700f84-4395-11eb-0728-f9c7a615f399
md"Obecnie masz zaoszczędzonych PLN $(@bind initial_investment NumberField(0:1e7, default=Int(5e3)))."

# ╔═╡ c2ed1baa-4395-11eb-2391-b9155da66af2
md"Miesięczna kwota, którą otrzymujesz od pracodawcy (przed PIT, ale po składkach na ZUS), to PLN $(@bind monthly_revenue NumberField(0:1e5, default=Int(3e3))), z których wydajesz PLN $(@bind monthly_cost NumberField(0:1e5, default=Int(2e3))) w przeciętnym miesiącu."

# ╔═╡ c4470892-4397-11eb-305d-c3fe29382c16
md"""
## Założenia ekonomiczne
"""

# ╔═╡ cfc9b566-4397-11eb-231c-37c0da3c3da2
md"Docelowa wartość inflacji NBP wynosi $(@bind yearly_inflation_percent NumberField(0:0.1:10, default=2.5))%. Zakładamy, że wszystkie kwoty skalują się wraz z inflacją."

# ╔═╡ 7711e8d8-43d0-11eb-01fd-8faca7a26c5d
md"Średnia roczna stopa zwrotu globalnego rynku wynosi $(@bind market_real_return_percent NumberField(0:0.1:100, default=4.3))% po korekcie na inflację, a odchylenie standardowe wynosi $(@bind market_stddev_percent NumberField(0:0.1:100, default=15))%."

# ╔═╡ fb8df1d8-43d0-11eb-1cd0-655f5240b570
md"""
Z kolei obligacje skarbowe zwracają marżę $(@bind bond_premium_percent NumberField(0:0.01:10, default=1))% powyżej inflacji.
"""

# ╔═╡ 8cfda320-43e5-11eb-1d02-d5d21784a008
begin
	yearly_bond_returns = 1 + yearly_inflation_percent / 100 + bond_premium_percent / 100
	md"To oznacza, że pieniądze zainwestowane w obligacje Skarbu Państwa pomnażają się o $(yearly_bond_returns) co roku."
end

# ╔═╡ 2896e0a6-4398-11eb-07dd-e5c27ac014a7
md"Stawka PIT wynosi $(@bind pit_first_percent NumberField(0:0.1:100, default=17))% w pierwszym progu i $(@bind pit_second_percent NumberField(0:0.1:100, default=32))% w drugim. Kwota graniczna to PLN $(@bind current_pit_bracket_border NumberField(0:1e6, default=85528))."

# ╔═╡ d7496936-4468-11eb-0247-579dfe77adb0
md"""
Podatek Belki wynosi $(@bind capital_gains_tax_percent NumberField(0:0.1:100, default=19))%.
"""

# ╔═╡ 3a29e51c-4397-11eb-35e6-7bef72a87db9
md"""
## Strategia inwestycyjna
"""

# ╔═╡ 3ca08438-43e0-11eb-004f-17a75401c481
md"Swoje obecne oszczędności zainwestujesz w: `obligacje` $(@bind initial_etf_allocation Slider(0:0.1:1, default=0.5)) `ETFy`"

# ╔═╡ 6879734c-4397-11eb-20b1-c521c4d1dbbf
md"""
### IKE
IKE to rachunek oszczędnościowy, który pozwala nie płacić podatku Belki, jeśli wyciąga się z niego pieniądze dopiero po 60ce. Maksymalna kwota, którą można wpłacić na IKE w ciągu jednego roku, wynosi PLN $(@bind ike_yearly_limit NumberField(0:1e5, default=15681)).
"""

# ╔═╡ 2fee2ecc-43de-11eb-0168-2943ab290ff0
begin
	md"""
W przeciętnym roku zamierzasz wpłacać na swoje IKE PLN $(@bind current_ike_yearly NumberField(0:0.01:ike_yearly_limit, default=1000)).
	"""
end

# ╔═╡ ea083430-43df-11eb-10a8-0d3e898644f8
md"Środki na IKE zainwestujesz w: `obligacje` $(@bind ike_etf_allocation Slider(0:0.1:1, default=0.5)) `ETFy`"

# ╔═╡ 9eb214ce-43dc-11eb-29a4-2712e312f969
md"""
### IKZE
IKZE to rachunek oszczędnościowy, który pozwala odliczyć kwotę wpłaconą na niego od swoich zarobków na potrzeby PIT. Wyciągnięcie pieniędzy z IKZE może nastąpić w wieku lat 65. Całość wypłaty podlega wtedy opodatkowaniu w wyskości $(@bind ikze_tax_percent NumberField(0:0.1:100, default=10))%. Na IKZE można maksymalnie wpłacać PLN $(@bind ikze_yearly_limit NumberField(0:1e5, default=6272.4)) w ciągu roku.
"""

# ╔═╡ b3a46636-43df-11eb-233b-3d178928ffe6
begin
	md"""
W przeciętnym roku zamierzasz wpłacać na swoje IKZE PLN $(@bind current_ikze_yearly NumberField(0:0.01:ikze_yearly_limit, default=1000)).
	"""
end

# ╔═╡ 16ba6086-43e0-11eb-280b-232a403709bb
md"Środki na IKZE zainwestujesz w: `obligacje` $(@bind ikze_etf_allocation Slider(0:0.1:1, default=0.5)) `ETFy`"

# ╔═╡ 32f6e32a-43e3-11eb-14e5-c9a22c45ca46
md"## Emerytura"

# ╔═╡ c1f30f50-44aa-11eb-28c0-a3d329b9947d
md"Będąc na emeryturze ulokujesz te pieniądze w: `obligacje` $(@bind retirement_etf_allocation Slider(0:0.1:1, default=0)) `ETFy`"

# ╔═╡ 27cd099c-4394-11eb-0cc0-eb21f9c082c5
md"## Technikalia"

# ╔═╡ 1cc75e60-4454-11eb-0cbf-bf4345f74eb5
num_samples = 4096

# ╔═╡ 2fdc63aa-44af-11eb-388d-43a2ca018a64
extrema(ecdf([1, 2, 3]))

# ╔═╡ 7a4ce2d4-44af-11eb-1858-810014c125bf
minimum([1, 2, 3])

# ╔═╡ 1ccbe7e6-4454-11eb-3d5f-13c7f8ed6c89
display_money(money) =
if money < 1e3
	"$(Int(round(money)))"
elseif money < 1e5
	"$(round(money / 1e3, digits=1))K"
elseif money < 1e6
	"$(Int(round(money / 1e3)))K"
elseif money < 1e8
	"$(round(money / 1e6, digits=1))M"
else
	"$(Int(round(money / 1e6)))M"
end

# ╔═╡ 64441bb6-4396-11eb-34e7-49024ebb7bb1
if monthly_cost > monthly_revenue
	md"#### 🚨 Miesięczne wydatki przekraczają miesięczne dochody. Mam nadzieję, że to nieprawda?"
else
	current_yearly_revenue = monthly_revenue * 12
	current_yearly_cost = monthly_cost * 12
	md"To oznacza, że wydajesz $(Int(round(monthly_cost / monthly_revenue * 100)))% swoich zarobków w przeciętnym miesiącu. Te wartości przeliczają się na roczny przychód w wysokości PLN $(display_money(current_yearly_revenue)) i roczne wydatki w wysokości PLN $(display_money(current_yearly_cost))."
end

# ╔═╡ 48c32c58-44a0-11eb-3cf4-6d11bebf21e0
function life_expectancy(; age, sex)
	known_ages = 0:15:75
	male_life_expectancies = known_ages .+ [74.1, 59.5, 45.1, 31.3, 19.3, 10.2]
	female_life_expectancies = known_ages .+ [81.8, 67.2, 52.4, 37.8, 24.2, 12.6]
	if sex == "male"
		CubicSplineInterpolation(known_ages, male_life_expectancies)(age)
	elseif sex == "female"
		CubicSplineInterpolation(known_ages, female_life_expectancies)(age)
	else
		throw("Unknown gender")
	end
end

# ╔═╡ 58c7e838-44a1-11eb-1906-ddf46510ff27
begin
	sex = if sex_pl == "mężczyzną" "male" else "female" end
	expected_death_age = life_expectancy(age=current_age, sex=sex)
	md"W takim razie, według GUS, spodziewasz się dożyć wieku lat $(Int(round(expected_death_age)))."
end

# ╔═╡ cf2e6344-44a1-11eb-30f3-230d34760865
begin
	years_to_retirement = age_at_retirement - current_age
	years_after_retirement = expected_death_age - age_at_retirement
	md"Masz więc przed sobą $(Int(round(years_to_retirement))) lat pracy, a na emeryturze spodziewasz się pożyć $(Int(round(years_after_retirement))) lat."
end

# ╔═╡ 8c8a52d2-4398-11eb-0549-493b3968b3b7
begin
	inflation_progress = (1 + yearly_inflation_percent / 100) .^ (0:years_to_retirement - 1)
	inflation_at_retirement = last(inflation_progress)
	yearly_revenues = current_yearly_revenue .* inflation_progress
	yearly_costs = current_yearly_cost .* inflation_progress
	md"To oznacza, że za $(years_to_retirement) lat będziesz potrzebować PLN $(display_money(monthly_cost * inflation_at_retirement)), aby utrzymać obecny styl życia, ponieważ PLN 1 będzie wart tyle, co PLN $(round(1 / inflation_at_retirement, digits=2)) obecnie. Ponieważ Twoje zarobki również będą skalować się z inflacją, to tuż przed emeryturą będziesz zarabiać PLN $(display_money(monthly_revenue * inflation_at_retirement))."
end

# ╔═╡ c6e26108-44a7-11eb-1350-a169fbac1b06
begin
	pit_bracket_borders = current_pit_bracket_border .* inflation_progress
	md"Zakładamy, że stawka graniczna PIT będzie również zwiększać się wraz z inflacją, aż do PLN $(display_money(last(pit_bracket_borders))), gdy będziesz przechodzić na emeryturę."
end

# ╔═╡ 1ccb3f4e-4454-11eb-2454-4378dd84a438
function wealth_plot(samples; title)
	real_samples = samples / inflation_at_retirement
	real_cdf = ecdf((real_samples)[:, 1])
	nominal_cdf = ecdf((samples)[:, 1])
	
	x_axis = LinRange(0, quantile(samples[:, 1], 0.99) * 1.1, 256)
	plot(title=title, xformatter=display_money)
	plot!(x_axis, real_cdf.(x_axis), label="Realna")
	plot!(x_axis, nominal_cdf.(x_axis), label="Nominalna")
end

# ╔═╡ c12bae28-449c-11eb-227c-03c3adef27c8
begin
	test_ages = 0:75
	plot(title="Life expectancy test")
	plot!(test_ages, life_expectancy.(age=test_ages, sex="male"), label="male")
	plot!(test_ages, life_expectancy.(age=test_ages, sex="female"), label="female")
end

# ╔═╡ 00b3aac6-4468-11eb-073d-9b52308d3240
function apply_pit(incomes)
	first_bracket_tax = min.(incomes, pit_bracket_borders) * pit_first_percent / 100
	second_bracket_tax = max.(incomes - pit_bracket_borders, 0) * pit_second_percent / 100
	return incomes - first_bracket_tax - second_bracket_tax
end

# ╔═╡ bd353520-4396-11eb-1250-2f5bbbca4582
begin
	current_post_pit = first(apply_pit(vcat(current_yearly_revenue, fill(0, years_to_retirement - 1))))
	current_yearly_tax = current_yearly_revenue - current_post_pit
	current_yearly_profit = current_post_pit - current_yearly_cost
	tax_bracket_message = if current_yearly_revenue > current_pit_bracket_border "wpadasz" else "nie wpadasz" end
	md"To oznacza, że $(tax_bracket_message) w drugi próg podatkowy, i co roku płacisz PIT w wysokości PLN $(display_money(current_yearly_tax)), co pozostawia PLN $(display_money(current_yearly_profit)) w formie oszczędności."
end

# ╔═╡ ac52378a-4468-11eb-17ef-530a18afa526
apply_pit(vcat(1e3, fill(0, years_to_retirement - 1)))

# ╔═╡ 295801a8-4469-11eb-0c9d-f149f78e3aa3
apply_pit(vcat(1e6, fill(0, years_to_retirement - 1)))

# ╔═╡ 5b5a3b60-44aa-11eb-15f9-77f12d39b6ab
apply_pit(vcat(fill(0, years_to_retirement - 1), 1e6))

# ╔═╡ 1cde325c-4454-11eb-33dc-afd84672f28d
function apply_capital_gains_tax(; incomes, samples)
	taxable = max.(sum(incomes), samples) .- sum(incomes)
	return samples .- taxable * capital_gains_tax_percent / 100
end

# ╔═╡ 280641c2-4460-11eb-2393-d54e120ff678
apply_capital_gains_tax(incomes=[1, 1], samples=[1, 2, 3])

# ╔═╡ 1d061cf6-4454-11eb-39b8-bb3618a42422
function sample_money(; incomes, return_samples)
	return_cumprod = cumprod(return_samples, dims=2)
	income_contributions = reverse(return_cumprod, dims=2) .* reshape(incomes, (1, size(incomes)...))
	return sum(income_contributions, dims=2)
end

# ╔═╡ 1cde875c-4454-11eb-01c2-276e071225f5
function sample_bonds(incomes)
	return sample_money(
		incomes=incomes,
		return_samples=fill(yearly_bond_returns, (num_samples, length(incomes)))
	)
end

# ╔═╡ fa5f43f2-4461-11eb-0a92-9339d712661a
sample_bonds([0, 1])

# ╔═╡ 1cfa81be-4454-11eb-31d3-eb0f7d8b680e
sample_money(incomes=[1, 2, 3], return_samples=[[1 1 1]; [2 2 2]])

# ╔═╡ 1d1a25fa-4454-11eb-272f-39ca1d358886
function mle_returns_distribution(samples)
	eps = 1e-2
	if std(samples) < eps
		Uniform(mean(samples) - eps, mean(samples) + eps)
	else
		truncated(fit_mle(Laplace, samples), 0, 2 * mean(samples))
	end
end

# ╔═╡ 1d1ad75c-4454-11eb-1e25-f9bf9054ee12
returns_distribution(mean, stddev) = truncated(Laplace(mean, stddev / sqrt(2)), 0, 2 * mean)

# ╔═╡ 863a0768-43d1-11eb-223d-e5fcd18b9417
begin
	market_multiplier_yearly = (1 + market_real_return_percent / 100) * (1 + yearly_inflation_percent / 100)
	market_yearly_distribution = returns_distribution(market_multiplier_yearly, market_stddev_percent / 100)
	md"Bez korekty na inflację, średni roczny wzrost rynku wynosi więc $(market_multiplier_yearly)."
end

# ╔═╡ 1cea9d4e-4454-11eb-3e99-b1183d499d25
function sample_etfs(incomes)
	return sample_money(
		incomes=incomes,
		return_samples=rand(market_yearly_distribution, (num_samples, length(incomes)))
	)
end

# ╔═╡ 7da0d500-4467-11eb-36a3-ad3a82e22318
begin
	plot(title="Rozkład wzrostu rynku")
	plot!(market_yearly_distribution, func=cdf, label="Roczny")
	plot!(mle_returns_distribution(sample_etfs(vcat([1], fill(0, years_to_retirement - 1)))), func=cdf, label="Do emerytury")
end

# ╔═╡ bdf9d4a4-4461-11eb-2705-f10e85e344c7
sample_portfolio(; incomes, etf_allocation) = (
	(1 - etf_allocation) .* sample_bonds(incomes)
	.+ etf_allocation .* sample_etfs(incomes)
)

# ╔═╡ 5bb7fcfc-43e5-11eb-0f55-c9bdd6557449
begin
	initial_incomes = zeros(years_to_retirement)
	initial_incomes[1] = initial_investment
	initial_samples = apply_capital_gains_tax(
		incomes=initial_incomes,
		samples=sample_portfolio(
			incomes=initial_incomes,
			etf_allocation=initial_etf_allocation
		)
	)
	wealth_plot(initial_samples, title="Wartość obecnych oszczędności na początku emerytury")
end

# ╔═╡ b4308f9a-43ef-11eb-244f-75e1e3b1851a
begin
	ike_incomes = current_ike_yearly * inflation_progress
	ike_samples = sample_portfolio(
		incomes=ike_incomes,
		etf_allocation=ike_etf_allocation
	)
	wealth_plot(ike_samples, title="Wartość IKE na początku emerytury")
end

# ╔═╡ 5816674a-43f0-11eb-34f6-09a53fc611fd
begin
	ikze_incomes = current_ikze_yearly .* inflation_progress
	ikze_samples = sample_portfolio(
		incomes=ikze_incomes,
		etf_allocation=ikze_etf_allocation
	) .* (1 - ikze_tax_percent / 100)
	wealth_plot(ikze_samples, title="Wartość IKZE na początku emerytury")
end

# ╔═╡ 002bc00c-43e1-11eb-0dad-c9e4ca4ca2f5
begin
	post_ikze_revenues = yearly_revenues - ikze_incomes
	post_ikze_yearly_taxes = post_ikze_revenues - apply_pit(post_ikze_revenues)
	post_ikze_yearly_profits = apply_pit(yearly_revenues - ikze_incomes) - yearly_costs
	md"To zmniejszy Twój roczny PIT o PLN $(display_money(current_yearly_tax - first(post_ikze_yearly_taxes))), do wartości PLN $(display_money(first(post_ikze_yearly_taxes)))."
end

# ╔═╡ eaa4fd02-43e0-11eb-1fe6-03f1d6b2bffb
begin
	yearly_unused = first(post_ikze_yearly_profits - ike_incomes - ikze_incomes)
	if yearly_unused < 0
		md"#### 🚨 Łączna kwota wpłacana na IKE i IKZE przekracza kwotę przychodu - PLN $(Int(round(post_ikze_yearly_profit))). Zmniejsz kwotę wpłacaną na te rachunki o PLN $(Int(round(-yearly_unused)))."
	else
		md"Po wpłacie na IKE oraz IKZE pozostaje Ci co roku PLN $(Int(round(yearly_unused))), które zostawiasz na koncie w banku."
	end
end

# ╔═╡ 48ed7d74-43e3-11eb-0976-c52b73747a52
begin
	overall_samples = initial_samples + ike_samples + ikze_samples .+ (yearly_unused * years_to_retirement)
	wealth_plot(overall_samples, title="Wartość majątku na początku emerytury")
end

# ╔═╡ d70da254-44ac-11eb-1db0-0f242bcc37ae
begin
	# uses 3% rule as per https://bestinterest.blog/updated-trinity-study-simulation/
	overall_monthly_retirement_samples = (
		(1 - retirement_etf_allocation) * (overall_samples / years_after_retirement)
		+ retirement_etf_allocation * .03 * overall_samples
	) / 12
	wealth_plot(overall_monthly_retirement_samples, title="Dodatkowa miesięczna emerytura (z podziału majątku)")
end

# ╔═╡ 93f5cde8-4466-11eb-387f-6147108da4d9
sample_portfolio(incomes=[0, 1], etf_allocation=0.01)

# ╔═╡ Cell order:
# ╟─2c367f68-4394-11eb-1098-23e08449a7dd
# ╟─12dca160-44a1-11eb-1950-b3a0b9f380a3
# ╟─58c7e838-44a1-11eb-1906-ddf46510ff27
# ╟─0dda613c-4395-11eb-2c8e-ff08529d84e8
# ╟─cf2e6344-44a1-11eb-30f3-230d34760865
# ╟─5e700f84-4395-11eb-0728-f9c7a615f399
# ╟─c2ed1baa-4395-11eb-2391-b9155da66af2
# ╟─64441bb6-4396-11eb-34e7-49024ebb7bb1
# ╟─c4470892-4397-11eb-305d-c3fe29382c16
# ╟─cfc9b566-4397-11eb-231c-37c0da3c3da2
# ╟─8c8a52d2-4398-11eb-0549-493b3968b3b7
# ╟─7711e8d8-43d0-11eb-01fd-8faca7a26c5d
# ╟─863a0768-43d1-11eb-223d-e5fcd18b9417
# ╟─7da0d500-4467-11eb-36a3-ad3a82e22318
# ╟─fb8df1d8-43d0-11eb-1cd0-655f5240b570
# ╟─8cfda320-43e5-11eb-1d02-d5d21784a008
# ╟─2896e0a6-4398-11eb-07dd-e5c27ac014a7
# ╟─bd353520-4396-11eb-1250-2f5bbbca4582
# ╟─c6e26108-44a7-11eb-1350-a169fbac1b06
# ╟─d7496936-4468-11eb-0247-579dfe77adb0
# ╟─3a29e51c-4397-11eb-35e6-7bef72a87db9
# ╟─3ca08438-43e0-11eb-004f-17a75401c481
# ╟─5bb7fcfc-43e5-11eb-0f55-c9bdd6557449
# ╟─6879734c-4397-11eb-20b1-c521c4d1dbbf
# ╟─2fee2ecc-43de-11eb-0168-2943ab290ff0
# ╟─ea083430-43df-11eb-10a8-0d3e898644f8
# ╟─b4308f9a-43ef-11eb-244f-75e1e3b1851a
# ╟─9eb214ce-43dc-11eb-29a4-2712e312f969
# ╟─b3a46636-43df-11eb-233b-3d178928ffe6
# ╟─002bc00c-43e1-11eb-0dad-c9e4ca4ca2f5
# ╟─16ba6086-43e0-11eb-280b-232a403709bb
# ╟─5816674a-43f0-11eb-34f6-09a53fc611fd
# ╟─eaa4fd02-43e0-11eb-1fe6-03f1d6b2bffb
# ╟─32f6e32a-43e3-11eb-14e5-c9a22c45ca46
# ╟─48ed7d74-43e3-11eb-0976-c52b73747a52
# ╟─c1f30f50-44aa-11eb-28c0-a3d329b9947d
# ╟─d70da254-44ac-11eb-1db0-0f242bcc37ae
# ╟─27cd099c-4394-11eb-0cc0-eb21f9c082c5
# ╠═1cc75e60-4454-11eb-0cbf-bf4345f74eb5
# ╠═2fdc63aa-44af-11eb-388d-43a2ca018a64
# ╠═7a4ce2d4-44af-11eb-1858-810014c125bf
# ╠═1ccb3f4e-4454-11eb-2454-4378dd84a438
# ╠═1ccbe7e6-4454-11eb-3d5f-13c7f8ed6c89
# ╠═c12bae28-449c-11eb-227c-03c3adef27c8
# ╠═48c32c58-44a0-11eb-3cf4-6d11bebf21e0
# ╠═ac52378a-4468-11eb-17ef-530a18afa526
# ╠═295801a8-4469-11eb-0c9d-f149f78e3aa3
# ╠═5b5a3b60-44aa-11eb-15f9-77f12d39b6ab
# ╠═00b3aac6-4468-11eb-073d-9b52308d3240
# ╠═280641c2-4460-11eb-2393-d54e120ff678
# ╠═1cde325c-4454-11eb-33dc-afd84672f28d
# ╠═93f5cde8-4466-11eb-387f-6147108da4d9
# ╠═bdf9d4a4-4461-11eb-2705-f10e85e344c7
# ╠═fa5f43f2-4461-11eb-0a92-9339d712661a
# ╠═1cde875c-4454-11eb-01c2-276e071225f5
# ╠═1cea9d4e-4454-11eb-3e99-b1183d499d25
# ╠═1cfa81be-4454-11eb-31d3-eb0f7d8b680e
# ╠═1d061cf6-4454-11eb-39b8-bb3618a42422
# ╠═1d1a25fa-4454-11eb-272f-39ca1d358886
# ╠═1d1ad75c-4454-11eb-1e25-f9bf9054ee12
# ╠═c27386f4-4393-11eb-1fb2-43bf6a1d7de0
