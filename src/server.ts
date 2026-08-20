
import express from "express";

const app = express();
const port = 3000;

app.get("/", (req, res) => {
    res.status(200).json({
        mensagem: "Servidor rodando com sucesso!",
        version: "1.0.0",
        status: `Servidor rodando na porta ${port}`
    });
});

app.get("/categorias", (req, res) => {
    res.status(200).json({
        mensagem: "Categorias retornadas com sucesso!",
        categorias: [
            { id: 1, nome: "Bebidas" },
            { id: 2, nome: "Comidas" },
            { id: 3, nome: "Sobremesas" }
        ]
    });
});

app.get("/produtos", (req, res) => {
    res.status(200).json({
        mensagem: "Produtos retornados com sucesso!",
        produtos: [
            { id: 1, nome: "Coca-Cola", categoriaId: 1 },
            { id: 2, nome: "Pizza", categoriaId: 2 },
            { id: 3, nome: "Sorvete", categoriaId: 3 }
        ]
    });
});

app.listen(port, () => {
    console.log(`Servidor rodando na porta http://localhost:${port}`);
});