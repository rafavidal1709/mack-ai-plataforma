-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Tempo de geração: 12/08/2025 às 16:24
-- Versão do servidor: 5.7.23-23
-- Versão do PHP: 8.1.33

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Banco de dados: `ecovir28_mackai`
--

-- --------------------------------------------------------

--
-- Estrutura para tabela `encontro`
--

CREATE TABLE `encontro` (
  `id` int(11) NOT NULL,
  `grupo` int(11) NOT NULL,
  `periodo` int(11) NOT NULL,
  `data` timestamp NULL DEFAULT NULL,
  `nome` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `texto` text COLLATE utf8_unicode_ci NOT NULL,
  `video` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Despejando dados para a tabela `encontro`
--

INSERT INTO `encontro` (`id`, `grupo`, `periodo`, `data`, `nome`, `texto`, `video`, `created`, `updated`) VALUES
(1, 1, 2, '2024-08-12 21:00:00', 'A história do Perceptron', 'Visão geral sobre o Perceptron, sua história e importância no desenvolvimento do campo do aprendizado de máquina. ', 'rc9cFq8M-Ys', '2025-08-12 15:58:44', '2025-08-12 19:23:30'),
(2, 1, 2, '2024-08-19 21:00:00', 'Treinando a Rede', 'Para treinar a rede usa-se o algorítimo de backpropagation', 'rc9cFq8M-Ys', '2025-08-12 15:58:44', '2025-08-12 19:23:33');

-- --------------------------------------------------------

--
-- Estrutura para tabela `grupo`
--

CREATE TABLE `grupo` (
  `id` int(11) NOT NULL,
  `nome` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Despejando dados para a tabela `grupo`
--

INSERT INTO `grupo` (`id`, `nome`, `created`, `updated`) VALUES
(1, 'Aprendizagem de Máquina', '2025-08-12 12:53:33', '2025-08-12 12:53:33'),
(2, 'Processamento de Linguagem Natural', '2025-08-12 12:53:33', '2025-08-12 12:53:33'),
(3, 'Ética', '2025-08-12 12:53:33', '2025-08-12 12:53:33'),
(4, 'Projetos', '2025-08-12 12:53:33', '2025-08-12 12:53:33');

-- --------------------------------------------------------

--
-- Estrutura para tabela `periodo`
--

CREATE TABLE `periodo` (
  `id` int(11) NOT NULL,
  `nome` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Despejando dados para a tabela `periodo`
--

INSERT INTO `periodo` (`id`, `nome`, `created`, `updated`) VALUES
(1, '2024/1', '2025-08-12 12:54:42', '2025-08-12 12:54:42'),
(2, '2024/2', '2025-08-12 12:54:42', '2025-08-12 12:54:42'),
(3, '2025/1', '2025-08-12 12:54:42', '2025-08-12 12:54:42'),
(4, '2025/2', '2025-08-12 12:54:42', '2025-08-12 12:54:42');

--
-- Índices para tabelas despejadas
--

--
-- Índices de tabela `encontro`
--
ALTER TABLE `encontro`
  ADD PRIMARY KEY (`id`),
  ADD KEY `grupo` (`grupo`),
  ADD KEY `periodo` (`periodo`);

--
-- Índices de tabela `grupo`
--
ALTER TABLE `grupo`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `nome` (`nome`);

--
-- Índices de tabela `periodo`
--
ALTER TABLE `periodo`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `nome` (`nome`);

--
-- AUTO_INCREMENT para tabelas despejadas
--

--
-- AUTO_INCREMENT de tabela `encontro`
--
ALTER TABLE `encontro`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de tabela `grupo`
--
ALTER TABLE `grupo`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de tabela `periodo`
--
ALTER TABLE `periodo`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- Restrições para tabelas despejadas
--

--
-- Restrições para tabelas `encontro`
--
ALTER TABLE `encontro`
  ADD CONSTRAINT `encontro_ibfk_1` FOREIGN KEY (`grupo`) REFERENCES `grupo` (`id`),
  ADD CONSTRAINT `encontro_ibfk_2` FOREIGN KEY (`periodo`) REFERENCES `periodo` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
