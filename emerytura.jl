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
md"## Results"

# ╔═╡ 27cd099c-4394-11eb-0cc0-eb21f9c082c5
md"## Technicalities"

# ╔═╡ 63a9a050-43e5-11eb-18d3-b9a01b3a7b60
num_samples = 4096

# ╔═╡ 128bb4be-43ee-11eb-174c-bda51ab6dd38
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

# ╔═╡ cc733592-43ea-11eb-1680-674be3b4f526
function apply_capital_gains_tax(; incomes, samples)
	taxable = max.(sum(incomes), samples) .- sum(incomes)
	return samples .- taxable * capital_gains_tax_percent / 100
end

# ╔═╡ 2e5efc8e-43e9-11eb-2085-992b2bb0e415
function sample_money(; incomes, return_samples)
	return_cumprod = cumprod(return_samples, dims=2)
	income_contributions = reverse(return_cumprod, dims=2) .* reshape(incomes, (1, size(incomes)...))
	return sum(income_contributions, dims=2)
end

# ╔═╡ 2bf4fa46-43e6-11eb-3062-af36f804987a
function sample_bonds(incomes)
	return sample_money(
		incomes=incomes,
		return_samples=fill(yearly_bond_returns, (num_samples, length(incomes)))
	)
end

# ╔═╡ 4be44610-43e9-11eb-3826-fd0f912f140f
sample_money(incomes=[1, 2, 3], return_samples=[[1 1 1]; [2 2 2]])

# ╔═╡ cdefcc0c-43e3-11eb-05f7-a3ac48051b3c
function mle_returns_distribution(samples)
	eps = 1e-2
	if std(samples) < eps
		Uniform(mean(samples) - eps, mean(samples) + eps)
	else
		truncated(fit_mle(Laplace, samples), 0, 2 * mean(samples))
	end
end

# ╔═╡ 5340c3b4-43eb-11eb-0ef7-395556e136df
function wealth_plot(samples; title)
	wealth_distribution = mle_returns_distribution(samples)
	plot(title=title, xformatter=display_money)
	plot!(wealth_distribution / inflation_at_retirement, func=cdf, label="Realna")
	plot!(wealth_distribution, func=cdf, label="Nominalna")
end

# ╔═╡ 2ca0bbda-43d8-11eb-18c3-93c9a3b46e70
function returns_power(laplace, exponent)
	samples = rand(laplace, (num_samples, exponent))
	products = prod(samples, dims=2)
	return mle_returns_distribution(products)
end

# ╔═╡ d32af702-43d7-11eb-0c46-2b102654e254
returns_distribution(mean, stddev) = truncated(Laplace(mean, stddev / sqrt(2)), 0, 2 * mean)

# ╔═╡ 863a0768-43d1-11eb-223d-e5fcd18b9417
begin
	market_multiplier_yearly = (1 + market_real_return_percent / 100) * (1 + yearly_inflation_percent / 100)
	market_yearly_distribution = returns_distribution(market_multiplier_yearly, market_stddev_percent / 100)
	market_to_retirement_distribution = returns_power(market_yearly_distribution, years_to_retirement)
	plot(title="Rozkład wzrostu rynku")
	plot!(market_yearly_distribution, func=cdf, label="Roczny")
	plot!(market_to_retirement_distribution, func=cdf, label="Do emerytury")
end

# ╔═╡ 6663f948-43e6-11eb-3988-61c42e69613a
function sample_etfs(incomes)
	return sample_money(
		incomes=incomes,
		return_samples=rand(market_yearly_distribution, (num_samples, length(incomes)))
	)
end

# ╔═╡ 5bb7fcfc-43e5-11eb-0f55-c9bdd6557449
begin
	initial_incomes = zeros(years_to_retirement)
	initial_incomes[1] = initial_investment
	initial_samples = apply_capital_gains_tax(
		incomes=initial_incomes,
		samples=(
			(1 - initial_etf_allocation) .* sample_bonds(initial_incomes)
			.+ initial_etf_allocation .* sample_etfs(initial_incomes)
		)
	)
	wealth_plot(initial_samples, title="Wartość obecnych oszczędności na początku emerytury")
end

# ╔═╡ b4308f9a-43ef-11eb-244f-75e1e3b1851a
begin
	ike_incomes = fill(ike_yearly, years_to_retirement)
	ike_samples = (
		(1 - ike_etf_allocation) .* sample_bonds(ike_incomes)
		.+ ike_etf_allocation .* sample_etfs(ike_incomes)
	)
	wealth_plot(ike_samples, title="Wartość IKE na początku emerytury")
end

# ╔═╡ 5816674a-43f0-11eb-34f6-09a53fc611fd
begin
	ikze_incomes = fill(ikze_yearly, years_to_retirement)
	ikze_samples = (
		(1 - ikze_etf_allocation) .* sample_bonds(ikze_incomes)
		.+ ikze_etf_allocation .* sample_etfs(ikze_incomes)
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
# ╟─63a9a050-43e5-11eb-18d3-b9a01b3a7b60
# ╟─5340c3b4-43eb-11eb-0ef7-395556e136df
# ╟─128bb4be-43ee-11eb-174c-bda51ab6dd38
# ╟─cc733592-43ea-11eb-1680-674be3b4f526
# ╟─2bf4fa46-43e6-11eb-3062-af36f804987a
# ╟─6663f948-43e6-11eb-3988-61c42e69613a
# ╠═4be44610-43e9-11eb-3826-fd0f912f140f
# ╟─2e5efc8e-43e9-11eb-2085-992b2bb0e415
# ╟─2ca0bbda-43d8-11eb-18c3-93c9a3b46e70
# ╟─cdefcc0c-43e3-11eb-05f7-a3ac48051b3c
# ╟─d32af702-43d7-11eb-0c46-2b102654e254
# ╟─c27386f4-4393-11eb-1fb2-43bf6a1d7de0
