### A Pluto.jl notebook ###
# v0.12.18

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

# ╔═╡ 2b070490-5407-11eb-2ada-835079aa17ef
using PlutoUI

# ╔═╡ 23de7af0-5406-11eb-11a5-cdf151cd2329
md"""
# Zakup nieruchomości
Obliczenia kredytowe
"""

# ╔═╡ 242402ea-5407-11eb-39ef-d924c389fb1a
md"""
Posiadasz PLN $(@bind current_savings NumberField(0:1e6, default=Int(3e5))) oszczędności, z pomocą których chcesz kupić nieruchomość, która kosztuje PLN $(@bind flat_price NumberField(0:1e6, default=Int(5e5))).
"""

# ╔═╡ 952ba208-5408-11eb-3926-13412aa4fac0
begin
	missing_amount = max(0, flat_price - current_savings)
	md"""
	Brakuje Ci więc PLN $missing_amount, na które bierzesz kredyt.
	"""
end

# ╔═╡ ce6d4b20-5408-11eb-0ec6-052fa7759ce7
md"""
Kredyt bierzesz na $(@bind credit_months NumberField(0:600, default=300)) miesięcy. Prowizja wyniesie PLN $(@bind credit_upfront_cost NumberField(0:1e5, default=0)), a miesięczna rata PLN $(@bind credit_monthly_cost NumberField(0:1e4, default=Int(1e3))).
"""

# ╔═╡ 46187ee2-5409-11eb-3860-0df615d6dcf5
begin
	credit_full_years = Int(floor(credit_months / 12))
	credit_remainder_months = Int(credit_months - credit_full_years * 12)
	credit_duration_text = "$(credit_full_years) lat i $(credit_remainder_months) miesięcy"
	credit_nominal_cost = Int(round(credit_months * credit_monthly_cost + credit_upfront_cost))
	md"""
	Tak więc w ciągu $credit_duration_text zapłacisz bankowi łącznie PLN $credit_nominal_cost.
	"""
end

# ╔═╡ 24e6c2e4-540a-11eb-13de-8bebf96e2d6a
begin
	inflation_yearly = 1.025
	inflation_monthly = inflation_yearly ^ (1 / 12)
	credit_adjusted_monthly = credit_monthly_cost ./ inflation_monthly .^ (0:(credit_months - 1))
	credit_adjusted_cost = Int(round(credit_upfront_cost + sum(credit_adjusted_monthly)))
	md"""
	Trzeba jednak pamiętać o inflacji, która wyniesie około $(round(inflation_yearly * 100 - 100, digits=1))% w skali roku. W dzisiejszych złotówkach ostatnia rata kredytu wyniesie tylko PLN $(round(last(credit_adjusted_monthly), digits=2)), więc całkowity koszt kredytu w dzisiejszych złotówkach to PLN $(credit_adjusted_cost).
	"""
end

# ╔═╡ 2a363f10-542d-11eb-2848-dd2a90693feb
md"""
## Alternatywna rzeczywistość
"""

# ╔═╡ 5d729210-540b-11eb-3e95-c9d14e06aa84
md"""
Obecnie mieszkasz w wynajętym lokalu. Najem oraz czynsz wynoszą razem PLN $(@bind current_rent NumberField(0:1e4, default=1800)). W zakupionej nieruchomości płaciłabyś tylko PLN $(@bind ownership_cost NumberField(0:1e3, default=300)) czynszu. Zakładamy, że dodatkowe opłaty (media etc) są takie same w obu wypadkach.
"""

# ╔═╡ 4e891cba-540b-11eb-1876-bb6451dbe2ce
md"""
## Technikalia
"""

# ╔═╡ 49e02758-5438-11eb-3067-7bf9939d1ebb
begin
	etf_growth_yearly_adjusted = 1.044
	etf_growth_yearly = etf_growth_yearly_adjusted * inflation_yearly
	etf_growth_monthly = etf_growth_yearly ^ (1 / 12)
end

# ╔═╡ e4581916-542a-11eb-3f35-57bd462723d6
begin
	real_estate_growth_yearly_adjusted = 1 + (etf_growth_yearly_adjusted - 1) / 2
	real_estate_growth_yearly = real_estate_growth_yearly_adjusted * inflation_yearly
	real_estate_growth_monthly = real_estate_growth_yearly ^ (1 / 12)
	flat_sale_price = flat_price * real_estate_growth_monthly ^ credit_months
	md"""
	Można oczekiwać, że wartość nominalna Twojej nowo nabytej nieruchomości wzrośnie do około PLN $(Int(round(flat_sale_price))) przez czas trwania kredytu, ponieważ prognoza rocznego wzrostu dla rynku mieszkaniowego to $(round(real_estate_growth_yearly * 100 - 100, digits=1))% nominalnie.
	"""
end

# ╔═╡ 668312e0-5437-11eb-3ef7-9daab4e05bae
function diff_text(diff)
	if diff < 0
		"PLN $(-Int(round(diff))) mniej"
	else
		"PLN $(Int(round(diff))) więcej"
	end
end

# ╔═╡ 262850be-5436-11eb-1eae-93ed297f86c3
capital_gains_tax = .19

# ╔═╡ 881d7b4c-542e-11eb-1911-910c21a3dd70
begin
	flat_sale_tax = capital_gains_tax * (flat_sale_price - flat_price)
	final_flat_value = flat_sale_price - flat_sale_tax
	md"""
	W związku z tym, gdybyś miała tę nieruchomość sprzedać na koniec kredytu, zapłaciłabyś PLN $(Int(round(flat_sale_tax))) podatku, co pozostawia PLN $(Int(round(final_flat_value))). Nie musisz oczywiście jej sprzedawać - w tym obliczeniu chodzi tylko o porównanie z sytuacją, w której np. postanowiłabyś nie brać teraz kredytu i kupić analogiczną nieruchomość później.
	"""
end

# ╔═╡ 9d74de0c-5435-11eb-278d-b93694cb4f67
function taxed_income(; investment, num_months, monthly_growth)
	pre_tax = investment * monthly_growth ^ num_months
	return pre_tax - (pre_tax - investment) * capital_gains_tax
end

# ╔═╡ 485b3106-540c-11eb-00ee-c9bcf85f26b2
begin
	renting_advantage_monthly = credit_monthly_cost + ownership_cost - current_rent
	renting_advantages_sum = sum(
		[
			taxed_income(
				investment=renting_advantage_monthly * inflation_monthly ^ month,
				num_months=credit_months - month,
				monthly_growth=etf_growth_monthly
			)
			for month in 0:(credit_months-1)
		]
	)
	md"""
	Co miesiąc będziesz więc wydawać $(diff_text(renting_advantage_monthly)), niż gdybyś kontynuowała mieszkanie w obecnie wynajmowanym lokalu. Jeśli będziesz inwestować te pieniądze, przełoży się to na $(diff_text(-renting_advantages_sum)) przez cały okres kredytu.
	"""
end

# ╔═╡ 1dc274a8-5430-11eb-0337-e91ce245e49d
begin
	current_savings_accumulated = taxed_income(investment=current_savings, monthly_growth=etf_growth_monthly, num_months=credit_months)
	md"""
	Alternatywnie, gdybyś zamiast kupować nieruchomość zainwestowała pieniądze w globalnie zdywersyfikowane portfolio ETFów (oczekiwany nominalny wzrost $(round(etf_growth_yearly * 100 - 100, digits=1))% rocznie), za $credit_duration_text Twoje obecne oszczędności zamieniłyby się w PLN $(Int(round(current_savings_accumulated))).
	"""
end

# ╔═╡ 9643995c-5438-11eb-3497-1f0ad75266b9
begin
	renting_advantage_total = current_savings_accumulated + renting_advantages_sum + credit_nominal_cost - final_flat_value
	md"""
	#### Koniec końców, mieszkając nadal w wynajętym mieszkaniu, za $credit_duration_text miałabyś $(diff_text(renting_advantage_total)).
	"""
end

# ╔═╡ e936f42e-5435-11eb-34bd-bf825cb6c761
taxed_income(investment=100, monthly_growth=1.01, num_months=1)

# ╔═╡ Cell order:
# ╟─23de7af0-5406-11eb-11a5-cdf151cd2329
# ╟─242402ea-5407-11eb-39ef-d924c389fb1a
# ╟─952ba208-5408-11eb-3926-13412aa4fac0
# ╟─ce6d4b20-5408-11eb-0ec6-052fa7759ce7
# ╟─46187ee2-5409-11eb-3860-0df615d6dcf5
# ╟─24e6c2e4-540a-11eb-13de-8bebf96e2d6a
# ╟─2a363f10-542d-11eb-2848-dd2a90693feb
# ╟─5d729210-540b-11eb-3e95-c9d14e06aa84
# ╟─485b3106-540c-11eb-00ee-c9bcf85f26b2
# ╟─e4581916-542a-11eb-3f35-57bd462723d6
# ╟─881d7b4c-542e-11eb-1911-910c21a3dd70
# ╟─1dc274a8-5430-11eb-0337-e91ce245e49d
# ╟─9643995c-5438-11eb-3497-1f0ad75266b9
# ╟─4e891cba-540b-11eb-1876-bb6451dbe2ce
# ╠═49e02758-5438-11eb-3067-7bf9939d1ebb
# ╠═668312e0-5437-11eb-3ef7-9daab4e05bae
# ╠═e936f42e-5435-11eb-34bd-bf825cb6c761
# ╠═9d74de0c-5435-11eb-278d-b93694cb4f67
# ╠═262850be-5436-11eb-1eae-93ed297f86c3
# ╠═2b070490-5407-11eb-2ada-835079aa17ef
