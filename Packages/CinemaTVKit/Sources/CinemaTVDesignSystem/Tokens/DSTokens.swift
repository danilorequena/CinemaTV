//
//  DSTokens.swift
//  CinemaTVKit
//
//  Escala única de espaçamento e raio. Substitui os .cornerRadius(16) e
//  paddings mágicos espalhados pela árvore antiga.
//

import SwiftUI

public enum DSSpacing {
    /// 4pt — separações mínimas (ícone/texto).
    public static let xs: CGFloat = 4
    /// 8pt — itens dentro de um mesmo grupo.
    public static let sm: CGFloat = 8
    /// 12pt — espaçamento entre cards em rails.
    public static let md: CGFloat = 12
    /// 16pt — margens de conteúdo.
    public static let lg: CGFloat = 16
    /// 24pt — separação entre seções.
    public static let xl: CGFloat = 24
    /// 32pt — respiro de blocos hero.
    public static let xxl: CGFloat = 32
}

public enum DSRadius {
    /// Cards e superfícies (16pt).
    public static let card: CGFloat = 16
    /// Posters e thumbnails (12pt).
    public static let poster: CGFloat = 12
}
