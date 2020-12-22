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
	using Statistics
	using StatsPlots
	gr(fmt=:png) # forces sensible plot size
	using PlutoUI
	md"Imports"
end

# ╔═╡ 2c367f68-4394-11eb-1098-23e08449a7dd
md"# Oszczędzanie
Na celowniku: godna emerytura."

# ╔═╡ 4dcb250c-4394-11eb-2f24-9f3f5aec7f10
md"Mamy $(@bind num_people NumberField(1:5, default=2)) osoby wspólnie oszczędzające na emeryturę."

# ╔═╡ 0dda613c-4395-11eb-2c8e-ff08529d84e8
md"Planujecie przejść na emeryturę za $(@bind years_to_retirement NumberField(0:50, default=20)) lat, a na emeryturze spodziewacie się przeżyć $(@bind years_after_retirement NumberField(0:50, default=20)) lat."

# ╔═╡ 5e700f84-4395-11eb-0728-f9c7a615f399
md"Obecnie macie zaoszczędzonych PLN $(@bind initial_investment NumberField(0:1e7, default=Int(200e3)))."

# ╔═╡ c2ed1baa-4395-11eb-2391-b9155da66af2
md"Wasze miesięczne płace, przed podatkiem, dają razem PLN $(@bind monthly_revenue NumberField(0:1e5, default=Int(10e3))), z których wydajecie PLN $(@bind monthly_cost NumberField(0:1e5, default=Int(5e3))) w przeciętnym miesiącu."

# ╔═╡ c4470892-4397-11eb-305d-c3fe29382c16
md"""
## Założenia ekonomiczne
"""

# ╔═╡ cfc9b566-4397-11eb-231c-37c0da3c3da2
md"Zakładamy inflację równą $(@bind yearly_inflation_percent NumberField(0:0.1:10, default=2.5))%."

# ╔═╡ 7711e8d8-43d0-11eb-01fd-8faca7a26c5d
md"Średnia roczna stopa zwrotu globalnego rynku, wynosi $(@bind market_real_return_percent NumberField(0:0.1:100, default=4.3))% po korekcie na inflację, a odchylenie standardowe wynosi $(@bind market_stddev_percent NumberField(0:0.1:100, default=15))%."

# ╔═╡ fb8df1d8-43d0-11eb-1cd0-655f5240b570
md"""
Z kolei obligacje skarbowe zwracają marżę $(@bind bond_premium_percent NumberField(0:0.1:10, default=1))% powyżej inflacji.
"""

# ╔═╡ 8cfda320-43e5-11eb-1d02-d5d21784a008
begin
	yearly_bond_returns = 1 + yearly_inflation_percent / 100 + bond_premium_percent / 100
	md"To oznacza, że pieniądze zainwestowane w obligacje Skarbu Państwa pomnażają się o $(yearly_bond_returns) co roku."
end

# ╔═╡ 2896e0a6-4398-11eb-07dd-e5c27ac014a7
md"Stawka PIT wynosi $(@bind personal_income_tax_percent NumberField(0:0.1:100, default=17))%, a podatek Belki - $(@bind capital_gains_tax_percent NumberField(0:0.1:100, default=19))%."

# ╔═╡ 3a29e51c-4397-11eb-35e6-7bef72a87db9
md"""
## Strategia inwestycyjna
"""

# ╔═╡ 3ca08438-43e0-11eb-004f-17a75401c481
md"Wasze obecne oszczędności zainwestujecie w: `obligacje` $(@bind initial_etf_allocation Slider(0:0.1:1, default=0.5)) `ETFy`"

# ╔═╡ 6879734c-4397-11eb-20b1-c521c4d1dbbf
md"""
### IKE
IKE to rachunek oszczędnościowy, który pozwala nie płacić podatku Belki, jeśli wyciąga się z niego pieniądze dopiero po 60ce. Maksymalna kwota, którą można wpłacić na IKE w ciągu jednego roku, wynosi PLN $(@bind ike_yearly_limit NumberField(0:1e5, default=15681)) - przy czym każde z was może mieć jedno IKE.
"""

# ╔═╡ 2fee2ecc-43de-11eb-0168-2943ab290ff0
begin
	ike_cumulative_yearly_limit = ike_yearly_limit * num_people
	md"""
Licząc razem, będziecie wpłacać na swoje IKE PLN $(@bind ike_yearly NumberField(0:0.01:ike_cumulative_yearly_limit, default=ike_cumulative_yearly_limit)) w ciągu roku, a limit prawny wynosi PLN $ike_cumulative_yearly_limit.
	"""
end

# ╔═╡ ea083430-43df-11eb-10a8-0d3e898644f8
md"Środki na IKE zainwestujecie w: `obligacje` $(@bind ike_etf_allocation Slider(0:0.1:1, default=0.5)) `ETFy`"

# ╔═╡ 9eb214ce-43dc-11eb-29a4-2712e312f969
md"""
### IKZE
IKZE to rachunek oszczędnościowy, który pozwala nam odliczyć kwotę wpłaconą na niego od swoich zarobków na potrzeby PIT. Wyciągnięcie pieniędzy z IKZE może nastąpić w wieku lat 65. Całość wypłaty podlega wtedy opodatkowaniu w wyskości $(@bind ikze_tax_percent NumberField(0:0.1:100, default=10))%. Na IKZE można maksymalnie wpłacać PLN $(@bind ikze_yearly_limit NumberField(0:1e5, default=6272.4)) w ciągu roku - przy czym, tak jak w wypadku IKE, każde z was może prowadzić jedno IKZE.
"""

# ╔═╡ b3a46636-43df-11eb-233b-3d178928ffe6
begin
	ikze_cumulative_yearly_limit = ikze_yearly_limit * num_people
	md"""
Licząc razem, będziecie wpłacać na swoje IKZE PLN $(@bind ikze_yearly NumberField(0:0.01:ikze_cumulative_yearly_limit, default=Int(5e3))) w ciągu roku, a limit prawny wynosi PLN $ikze_cumulative_yearly_limit.
	"""
end

# ╔═╡ 16ba6086-43e0-11eb-280b-232a403709bb
md"Środki na IKZE zainwestujecie w: `obligacje` $(@bind ikze_etf_allocation Slider(0:0.1:1, default=0.5)) `ETFy`"

# ╔═╡ 32f6e32a-43e3-11eb-14e5-c9a22c45ca46
md"## Wyniki"

# ╔═╡ 27cd099c-4394-11eb-0cc0-eb21f9c082c5
md"## Technikalia"

# ╔═╡ 1cc75e60-4454-11eb-0cbf-bf4345f74eb5
num_samples = 4096

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
	md"Miesięczne wydatki przekraczają miesięczne dochody. Mam nadzieję, że to nieprawda?"
else
	yearly_revenue = monthly_revenue * 12
	yearly_cost = monthly_cost * 12
	md"To oznacza, że wydajecie $(Int(round(monthly_cost / monthly_revenue * 100)))% swoich zarobków w przeciętnym miesiącu. Te wartości przeliczają się na roczny przychód w wysokości PLN $(display_money(yearly_revenue)) i roczne wydatki w wysokości PLN $(display_money(yearly_cost))."
end

# ╔═╡ 8c8a52d2-4398-11eb-0549-493b3968b3b7
begin
	inflation_at_retirement = (1 + yearly_inflation_percent / 100) .^ years_to_retirement
	md"To oznacza, że za $(years_to_retirement) lat będziecie potrzebować PLN $(display_money(monthly_cost * inflation_at_retirement)), aby utrzymać obecny styl życia, ponieważ PLN 1 będzie wart tyle, co PLN $(round(1 / inflation_at_retirement, digits=2)) obecnie."
end

# ╔═╡ bd353520-4396-11eb-1250-2f5bbbca4582
begin
	current_yearly_tax = yearly_revenue * personal_income_tax_percent / 100
	current_yearly_profit = yearly_revenue - yearly_cost - current_yearly_tax
	md"To oznacza, że co roku płacicie PIT w wysokości PLN $(display_money(current_yearly_tax)), co pozostawia PLN $(display_money(current_yearly_profit)) w formie oszczędności."
end

# ╔═╡ 002bc00c-43e1-11eb-0dad-c9e4ca4ca2f5
begin
	post_ikze_yearly_tax = (yearly_revenue - ikze_yearly) * personal_income_tax_percent / 100
	post_ikze_yearly_profit = yearly_revenue - yearly_cost - post_ikze_yearly_tax
	md"To zmniejszy wasz roczny PIT o PLN $(display_money(current_yearly_tax - post_ikze_yearly_tax)), do wartości PLN $(display_money(post_ikze_yearly_tax))."
end

# ╔═╡ eaa4fd02-43e0-11eb-1fe6-03f1d6b2bffb
begin
	yearly_unused = post_ikze_yearly_profit - ike_yearly - ikze_yearly
	if yearly_unused < 0
		md"Łączna kwota wpłacana na IKE i IKZE przekraczą kwotę przychodu - PLN $(Int(round(post_ikze_yearly_profit))). Musicie wpłacać PLN $(Int(round(-yearly_unused))) mniej na te rachunki."
	else
		md"Po wpłacie na IKE oraz IKZE pozostaje wam co roku PLN $(Int(round(yearly_unused))) na nieprzewidziane wydatki."
	end
end

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

# ╔═╡ 1ccb3f4e-4454-11eb-2454-4378dd84a438
function wealth_plot(samples; title)
	wealth_distribution = mle_returns_distribution(samples)
	plot(title=title, xformatter=display_money)
	plot!(wealth_distribution / inflation_at_retirement, func=cdf, label="Realna")
	plot!(wealth_distribution, func=cdf, label="Nominalna")
end

# ╔═╡ 1d1ad75c-4454-11eb-1e25-f9bf9054ee12
returns_distribution(mean, stddev) = truncated(Laplace(mean, stddev / sqrt(2)), 0, 2 * mean)

# ╔═╡ 863a0768-43d1-11eb-223d-e5fcd18b9417
begin
	market_multiplier_yearly = (1 + market_real_return_percent / 100) * (1 + yearly_inflation_percent / 100)
	market_yearly_distribution = returns_distribution(market_multiplier_yearly, market_stddev_percent / 100)
	plot(title="Rozkład wzrostu rynku")
	plot!(market_yearly_distribution, func=cdf, label="Roczny")
end

# ╔═╡ 1cea9d4e-4454-11eb-3e99-b1183d499d25
function sample_etfs(incomes)
	return sample_money(
		incomes=incomes,
		return_samples=rand(market_yearly_distribution, (num_samples, length(incomes)))
	)
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
	ike_incomes = fill(ike_yearly, years_to_retirement)
	ike_samples = sample_portfolio(
		incomes=ike_incomes,
		etf_allocation=ike_etf_allocation
	)
	wealth_plot(ike_samples, title="Wartość IKE na początku emerytury")
end

# ╔═╡ 5816674a-43f0-11eb-34f6-09a53fc611fd
begin
	ikze_incomes = fill(ikze_yearly, years_to_retirement)
	ikze_samples = sample_portfolio(
		incomes=ikze_incomes,
		etf_allocation=ikze_etf_allocation
	) .* (1 - ikze_tax_percent / 100)
	wealth_plot(ikze_samples, title="Wartość IKZE na początku emerytury")
end

# ╔═╡ 48ed7d74-43e3-11eb-0976-c52b73747a52
begin
	overall_samples = initial_samples + ike_samples + ikze_samples
	wealth_plot(overall_samples, title="Wartość majątku na początku emerytury")
end

# ╔═╡ 28920e72-4448-11eb-31d8-a793fe2aaccd
begin
	overall_monthly_retirement_samples = overall_samples / years_after_retirement / 12
	wealth_plot(overall_monthly_retirement_samples, title="Dodatkowa miesięczna emerytura (z podziału majątku)")
end

# ╔═╡ 93f5cde8-4466-11eb-387f-6147108da4d9
sample_portfolio(incomes=[0, 1], etf_allocation=0.01)

# ╔═╡ Cell order:
# ╟─2c367f68-4394-11eb-1098-23e08449a7dd
# ╟─4dcb250c-4394-11eb-2f24-9f3f5aec7f10
# ╟─0dda613c-4395-11eb-2c8e-ff08529d84e8
# ╟─5e700f84-4395-11eb-0728-f9c7a615f399
# ╟─c2ed1baa-4395-11eb-2391-b9155da66af2
# ╟─64441bb6-4396-11eb-34e7-49024ebb7bb1
# ╟─c4470892-4397-11eb-305d-c3fe29382c16
# ╟─cfc9b566-4397-11eb-231c-37c0da3c3da2
# ╟─8c8a52d2-4398-11eb-0549-493b3968b3b7
# ╟─7711e8d8-43d0-11eb-01fd-8faca7a26c5d
# ╟─863a0768-43d1-11eb-223d-e5fcd18b9417
# ╟─fb8df1d8-43d0-11eb-1cd0-655f5240b570
# ╟─8cfda320-43e5-11eb-1d02-d5d21784a008
# ╟─2896e0a6-4398-11eb-07dd-e5c27ac014a7
# ╟─bd353520-4396-11eb-1250-2f5bbbca4582
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
# ╟─28920e72-4448-11eb-31d8-a793fe2aaccd
# ╟─27cd099c-4394-11eb-0cc0-eb21f9c082c5
# ╠═1cc75e60-4454-11eb-0cbf-bf4345f74eb5
# ╠═1ccb3f4e-4454-11eb-2454-4378dd84a438
# ╠═1ccbe7e6-4454-11eb-3d5f-13c7f8ed6c89
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
