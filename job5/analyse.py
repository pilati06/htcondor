import sys
import os
import pandas as pd

def main():
    # Garante que o argumento com o nome do arquivo foi passado
    if len(sys.argv) < 2:
        print("Erro: Nome do arquivo não fornecido.")
        sys.exit(1)

    nome_arquivo = sys.argv[1]

    print(f"=== Iniciando processamento: {nome_arquivo} ===")

    # Leitura do CSV
    df = pd.read_csv(nome_arquivo)

    # Conversão de coluna de data
    df['data_hora'] = pd.to_datetime(df['data_hora'])

    # Cálculo de métricas agregadas
    total_registros = len(df)
    umidade_media = df['umidade_solo_pct'].mean()
    temp_max = df['temperatura_c'].max()
    temp_min = df['temperatura_c'].min()
    ndvi_medio = df['ndvi'].mean()

    # Saída padrão (será capturada pelo HTCondor no arquivo .out definido)
    print(f"Registros processados: {total_registros}")
    print(f"Umidade média do solo: {umidade_media:.2f}%")
    print(f"Temperatura máxima: {temp_max:.1f}°C")
    print(f"Temperatura mínima: {temp_min:.1f}°C")
    print(f"NDVI médio: {ndvi_medio:.3f}")

    # Alerta simples de estresse hídrico
    if umidade_media < 25.0:
        print("ALERTA: Umidade média do solo abaixo do limite ideal (25%).")

    print("=== Processamento concluído com sucesso ===")

if __name__ == "__main__":
    main()
