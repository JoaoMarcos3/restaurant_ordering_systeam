import crypto = require("crypto");
import express from "express";
import ( randomUUID ) from "node:crypto";


const app = express();
app.use(express.json());

//===============
//initial data
//===============
const pizzaCategoriaId = randomUUID();
const sorveteCategoriaId = randomUUID();   
const sobremesaCategoriaId = crypto.randomUUID(); 



const categorias = [
    { id: pizzaCategoriaId, nome: "Pizzas" },
    { id: sorveteCategoriaId, nome: "Sorvetes" },
    { id: sobremesaCategoriaId, nome: "Sobremesas" }   
];


const produtos = [
    { id: 1, nome: "Coca-Cola", categoriaId: pizzaCategoriaId },
    { id: 2, nome: "Pizza", categoriaId: pizzaCategoriaId },
    { id: 3, nome: "Sorvete", categoriaId: sorveteCategoriaId },
    { id: 4, nome: "Sobremesa", categoriaId: sobremesaCategoriaId }
];

app.get("/", (req, res) => {
    res.status(200).json({
        mensagem: "Servidor rodando com sucesso!",
        vesrsion: "1.0.0"
    }); 

});

app.get("/categorias", (req, res) => {  
     res.status(200).json({
        mensagem: "Categorias retornadas com sucesso!",
        categorias: categorias
    });
});

app.get("/produtos", (req, res) => {
    res.status(200).json({
        mensagem: "Produtos retornados com sucesso!",
        produtos: produtos  
    });
});
    
export default app;
