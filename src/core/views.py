from django.http import JsonResponse

from core.services import pricing_quote


def quote(request):
    units = int(request.GET.get("units", 1))
    return JsonResponse(pricing_quote(units))
