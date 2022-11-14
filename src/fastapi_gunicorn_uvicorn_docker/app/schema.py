from pydantic import BaseModel
from dataclasses import dataclass
from typing import Optional, List

@dataclass
class Produto(BaseModel):
    quantity: str
    id: str
    name: str
    brand: str
    price: str

@dataclass
class DataLayer(BaseModel):
    TipoEvento: str
    bandeira: str
    device: Optional[str] = None
    advertiserID: Optional[str] = None
    idUsuario: Optional[str] = None
    appsflyerID: Optional[str] = None
    clientId: Optional[str] = None
    sistemaOperacional: Optional[str] = None
    nomePagina: Optional[str] = None
    idTransacao: Optional[str] = None
    receita: Optional[float] = None
    skuProdutos: Optional[str] = None
    precoProdutos: Optional[float] = None
    qtdProdutos: Optional[int] = None
    produtos: Optional[List[Produto]] = None
    valorFrete: Optional[str] = None
    serverTime: Optional[str] = None
    eventCategory: Optional[str] = None
    eventAction: Optional[str] = None
    eventLabel: Optional[str] = None
    referrer: Optional[str] = None
    utmSource: Optional[str] = None
    utmMedium: Optional[str] = None
    utmCampaign: Optional[str] = None
    hitTime: Optional[str] = None

async def common_parameters(
    TipoEvento: str, 
    bandeira: str,
    nomePagina: Optional[str] = None, 
    device: Optional[str] = None,
    advertiserID: Optional[str] = None,
    clientId: Optional[str] = None,
    appsflyerID: Optional[str] = None,
    valorFrete: Optional[str] = None,
    serverTime: Optional[str] = None,
    idUsuario: Optional[str] = None,
    sistemaOperacional: Optional[str] = None,
    eventCategory: Optional[str] = None,
    eventAction: Optional[str] = None,
    eventLabel: Optional[str] = None,
    produtos: Optional[str] = None,
    skuProdutos: Optional[str] = "",
    qtdProdutos: Optional[str] = "",
    precoProdutos: Optional[str] = "",
    idTransacao: Optional[str] = None,
    referrer: Optional[str] = None,
    utmSource: Optional[str] = None,
	utmMedium: Optional[str] = None,
    utmCampaign: Optional[str] = None,
    hitTime: Optional[str] = None,
    receita: Optional[str] = None):
    return {
        "TipoEvento": TipoEvento,
        "nomePagina": nomePagina,
        "device": device,
        "idTransacao": idTransacao,
        "advertiserID": advertiserID,
        "clientId": clientId,
        "appsflyerID": appsflyerID,
        "valorFrete": valorFrete,
        "serverTime": serverTime,
        "idUsuario": idUsuario,
        "bandeira": bandeira,
        "sistemaOperacional": sistemaOperacional,
        "eventCategory": eventCategory,
        "eventAction": eventAction,
        "eventLabel": eventLabel,
        "produtos": produtos,
        "qtdProdutos": qtdProdutos.split(","),
        "skuProdutos": skuProdutos.split(","),
        "precoProdutos": precoProdutos.split(","),
        "referrer": referrer,
        "utmSource": utmSource,
		"utmMedium": utmMedium,
        "utmCampaign": utmCampaign,
        "receita": receita,
        "hitTime": hitTime,
    }