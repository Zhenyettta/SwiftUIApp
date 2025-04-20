//
//  PostListView.swift
//  SwiftUIApp
//
//  Created by Євген Анісімов on 4/20/25.
//

import SwiftUI

struct PostRowView: View {
    // MARK: - Properties

    let post: Post
    let image: UIImage?

    // MARK: - Body

    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            
            // MARK: Image View or Placeholder
            postImageView
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            // MARK: Text Content
            VStack(alignment: .leading, spacing: 5) {
                Text(post.title)
                    .font(.headline)
                    .lineLimit(2)

                Text("Автор: \(post.author)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(post.body)
                    .font(.body)
                    .foregroundColor(.gray)
                    .lineLimit(3)

                Text(post.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.tertiary)
                    .padding(.top, 2)
            }

            Spacer()
        }
        .padding(.vertical, 10)
    }

    // MARK: - Subviews

    /// Повертає View для зображення поста або плейсхолдер, якщо зображення немає.
    @ViewBuilder
    private var postImageView: some View {
        if let img = image {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
                .clipped()
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.15))
                Image(systemName: "photo.fill")
                    .foregroundColor(.gray.opacity(0.6))
                    .font(.title)
            }
        }
    }
}

// MARK: - Preview

struct PostRowView_Previews: PreviewProvider {
    static var previews: some View {
        let samplePost = Post(
            title: "Приклад довгого заголовка, який може не вміститися в один рядок",
            body: "Це приклад тексту поста, який може бути досить довгим і займати кілька рядків, тому ми обмежуємо його.",
            author: "Автор Прикладович",
            imageFileName: nil
        )
         let samplePostWithImage = Post(
             title: "Пост із зображенням",
             body: "Короткий опис поста.",
             author: "Фотограф",
             imageFileName: "placeholder"
         )
        let sampleImage = UIImage(systemName: "photo")

        VStack {
            PostRowView(post: samplePost, image: nil)
                .padding(.horizontal)
            Divider()
            PostRowView(post: samplePostWithImage, image: sampleImage)
                 .padding(.horizontal)
        }
        .previewLayout(.sizeThatFits)
    }
}
